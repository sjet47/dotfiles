//
// 通知守护 —— 替代 mako
//
// 对外接口(waybar 的 custom/notifications 模块在用):
//   qs ipc call notif dndToggle    切免打扰,返回 on/off
//   qs ipc call notif dndStatus    查免打扰
//   qs ipc call notif history      历史记录 JSON
//   qs ipc call notif invoke       触发最新一条的 default action(对应 makoctl invoke)
//   qs ipc call notif dismissAll   清空(对应 makoctl dismiss --all)
//
// 行为沿用被替代的 mako:浅色卡片、右上角、宽 420、默认 5s、critical 不自动消失且红边、
// 免打扰时只放行 notify-send、截图通知用大图。mako 的配置文件已随包删除,下面各处
// 行尾的 `// mako xxx` 注释就是这些数值的唯一出处,别删。
//
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
    id: notif

    required property string activeMonitor

    property bool  dnd: false
    property var   popups: []      // 正在显示的 Notification 对象
    property var   log: []         // 历史(纯数据,通知对象销毁后仍在)
    readonly property int maxLog: 50

    NotificationServer {
        id: server

        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true          // screenshot.sh / screenrecord.sh 靠 -A 拿点击结果
        persistenceSupported: true      // 我们自己留 history

        onNotification: function (n) {
            n.tracked = true;

            notif.log = [{
                appName: n.appName, summary: n.summary, body: n.body,
                urgency: n.urgency, time: Date.now()
            }].concat(notif.log).slice(0, notif.maxLog);

            // 免打扰:只放行 notify-send(和 mako 的 [mode=do-not-disturb app-name=notify-send] 一致)
            if (notif.dnd && n.appName !== "notify-send") return;

            notif.popups = [n].concat(notif.popups);

            // 发送方主动关闭(CloseNotification)或用 replaces_id 顶掉旧的时,对象会失效。
            // 不同步摘掉的话,popups 里留下失效引用,delegate 渲染成一张永不消失的空白卡片
            // —— 飞书的"报警"反复发,实测能堆出好几张。
            n.closed.connect(function () { notif.drop(n); });
        }
    }

    function drop(n) {
        notif.popups = notif.popups.filter(x => x !== n);
    }

    // IpcHandler 够不到 delegate(动画在 delegate 里),所以用信号让对应的卡片自己认领,
    // 这样 IPC 触发的关闭和鼠标点击走的是同一条动画路径。
    signal closeRequested(var target, var act)

    // 退场动画播完后的收尾。放在 Scope 上而不是 delegate 里:drop() 会销毁 delegate,
    // 让它在自己的方法执行到一半时把自己销毁掉不安全。
    function finishClose(n, act) {
        notif.drop(n);
        if (act) act(n);
    }

    IpcHandler {
        target: "notif"

        function dndToggle(): string { notif.dnd = !notif.dnd; return notif.dnd ? "on" : "off"; }
        function dndStatus(): string { return notif.dnd ? "on" : "off"; }
        function history(): string   { return JSON.stringify(notif.log); }

        // 对应 makoctl invoke / makoctl dismiss --all
        function invoke(): string {
            const n = notif.popups[0];
            if (!n) return "none";
            const def = (n.actions ?? []).find(a => a.identifier === "default");
            // 动作在动画结束后才执行,所以这里的返回值是"已受理"而非"已完成"
            notif.closeRequested(n, def ? (() => def.invoke()) : (nn => nn.dismiss()));
            return def ? "invoked" : "dismissed";
        }
        function dismissAll(): string {
            const c = notif.popups.length;
            // 不能在这里清空 popups:delegate 得活到动画播完,各自的 onFinished 会摘掉自己
            notif.popups.forEach(n => notif.closeRequested(n, nn => nn.dismiss()));
            return String(c);
        }
    }

    // 直接把 JS 数组喂给 Repeater 的话,数组一变整列 delegate 全部重建 —— 表现为
    // 某条自动消失时,其余卡片的缩略图会闪一下重新解码。ScriptModel 做增量 diff,
    // 只增删变化的那一项,存活的 delegate 不动。
    ScriptModel {
        id: popupModel
        values: notif.popups
    }

    // 只给当前活动屏建面板。若对所有屏建再靠 visible 控制,隐藏的那块也会照样
    // 实例化整列 delegate 并解码一遍图片(插桩实测每条 delegate 创建两次)。
    Variants {
        model: Quickshell.screens.filter(s => s.name === notif.activeMonitor)

        PanelWindow {
            id: panel
            required property var modelData

            screen: modelData
            visible: notif.popups.length > 0

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-notifications"
            // 不能 Ignore:那样会无视 waybar 的独占区,卡片压到状态栏上去
            // (实测 y=495 落在 waybar 的 479..510 区间内,而 mako 是 530)
            exclusionMode: ExclusionMode.Normal
            anchors { top: true; right: true }
            // 面板紧贴屏幕右边缘,卡片靠 stack 的宽度在内部留出 20px 间距。
            // 若给面板留 margin,退场向右滑出时会被面板边界裁掉,在屏幕内部形成
            // 一条可见的竖直硬边;贴边之后裁剪线与屏幕边缘重合,看起来就是正常滑出屏外。
            margins { top: 20; right: 0 }
            implicitWidth: 420 + 20             // mako width=420,再加右侧间距
            // 面板高度固定,不跟着卡片变。
            //
            // 早先的写法是 implicitHeight 绑定卡片总高、再加 Behavior 做过渡,结果等于
            // 每帧都在 resize Wayland layer surface —— 缓冲区尺寸与内容重绘不同步,
            // 上移过程中会出现旧位置内容残留的重影。
            //
            // 现在固定成整屏高,卡片在里面自由动;多出来的透明区域靠 mask 把输入放行,
            // 否则这块看不见的覆盖层会吃掉下面窗口的点击。
            implicitHeight: panel.screen.height - 40
            mask: Region { item: stack }
            color: "transparent"

            Column {
                id: stack
                width: parent.width - 20        // 右侧 20px 留给滑出,兼作 mako 的 outer-margin
                spacing: 10

                // 其余卡片让位/上移(默认是瞬间跳位)。新卡片的进场不在这里做:
                // 它插在 index 0,y 本来就是 0,add 过渡是空转 —— 而且那样它会
                // 立刻满不透明地出现在顶部,与还在下移的旧卡片重叠 220ms。
                // 进场交给 delegate 自己从屏幕右侧滑入,与这里的下移并行(参考 macOS)。
                move: Transition { NumberAnimation { properties: "y"; duration: 220; easing.type: Easing.OutCubic } }

                Repeater {
                    model: popupModel

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        readonly property var n: card.modelData

                        // macOS 的分槽:appIcon 是"应用自己的图标"放左,image 是"附件"放右。
                        // 这不是猜的 —— 实测 notify-send -i <路径> 进的是 image
                        // (值形如 image://icon/<路径>,appIcon 反而是空),
                        // 而 kitty / 飞书是 appIcon=自己的 logo 路径、image 为空。
                        readonly property string appIconSrc: {
                            const i = card.n.appIcon ?? "";
                            if (i === "") return "";
                            return (i.startsWith("/") || i.startsWith("file:")) ? i : Quickshell.iconPath(i, true);
                        }
                        readonly property string attachSrc: card.n.image ?? ""

                        // 非 default 的 action —— default 不画按钮,它是"点卡片"那一下
                        readonly property var actionList:
                            (card.n.actions ?? []).filter(a => a.identifier !== "default")
                        // 右槽二选一:有按钮就放按钮,否则放附件缩略图
                        readonly property var shownActions: card.actionList.slice(0, 2)

                        width: parent.width
                        // 高度固定,不跟内容长 —— 正文超过 2 行由 elide 截断。
                        // macOS 横幅就是定高的,长短不一的卡片堆在一起很乱。
                        height: 88
                        radius: 16
                        color: "#d9f5f5f7"
                        border.width: 1
                        border.color: card.n.urgency === NotificationUrgency.Critical ? "#ff453a"
                                    : card.n.urgency === NotificationUrgency.Low      ? "#e5e5ea"
                                    : "#d2d2d7"

                        // 初始位置在屏外右侧、全透明,由 enterAnim 拉进来。
                        transform: Translate { id: slide; x: 460 }
                        opacity: 0

                        ParallelAnimation {
                            id: enterAnim
                            running: true
                            NumberAnimation { target: slide; property: "x"
                                              to: 0; duration: 260; easing.type: Easing.OutCubic }
                            NumberAnimation { target: card; property: "opacity"
                                              to: 1; duration: 260; easing.type: Easing.OutCubic }
                        }

                        ParallelAnimation {
                            id: exitAnim
                            property var act: null
                            NumberAnimation {
                                target: slide; property: "x"
                                from: 0; to: card.width + 40
                                duration: 200; easing.type: Easing.InCubic
                            }
                            NumberAnimation {
                                target: card; property: "opacity"
                                from: 1; to: 0; duration: 200
                            }
                            onFinished: notif.finishClose(card.n, exitAnim.act)
                        }

                        Connections {
                            target: notif
                            function onCloseRequested(target, act) {
                                if (target === card.n) card.close(act);
                            }
                        }

                        function close(act) {
                            if (exitAnim.running) return;
                            exitAnim.act = act ?? null;
                            exitAnim.start();
                        }

                        // critical 不自动消失(mako 的 [urgency=critical] default-timeout=0)
                        Timer {
                            running: card.n.urgency !== NotificationUrgency.Critical
                            interval: card.n.expireTimeout > 0 ? card.n.expireTimeout : 5000
                            onTriggered: card.close(n => n.expire())
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function (mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    card.close(n => n.dismiss());
                                    return;
                                }
                                card.close(function (n) {
                                    const def = (n.actions ?? []).find(a => a.identifier === "default");
                                    if (def) def.invoke(); else n.dismiss();
                                });
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            // ── 左:应用图标 ──
                            Image {
                                visible: card.appIconSrc !== ""
                                source: card.appIconSrc
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                Layout.alignment: Qt.AlignVCenter
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                sourceSize.width: 80
                                sourceSize.height: 80
                            }

                            // ── 中:标题 + 正文 ──
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: card.n.summary ?? ""
                                    color: "#1d1d1f"
                                    font.family: "Noto Sans"
                                    font.pixelSize: 14
                                    font.bold: true
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: (card.n.body ?? "") !== ""
                                    // body 里是真换行符(0a),StyledText 是 HTML 语义会折叠成空格
                                    text: (card.n.body ?? "").replace(/\n/g, "<br/>")
                                    color: "#1d1d1f"
                                    font.family: "Noto Sans"
                                    font.pixelSize: 14
                                    textFormat: Text.StyledText
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2      // 定高卡片,正文最多两行
                                    elide: Text.ElideRight
                                }
                            }

                            // ── 右:按钮竖排(优先) ──
                            ColumnLayout {
                                visible: card.shownActions.length > 0
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 6

                                Repeater {
                                    model: card.shownActions

                                    delegate: Rectangle {
                                        id: btn
                                        required property var modelData

                                        Layout.preferredWidth: Math.max(64, label.implicitWidth + 20)
                                        Layout.preferredHeight: 26
                                        radius: 6
                                        color: hover.containsMouse ? "#26000000" : "#14000000"
                                        Behavior on color { ColorAnimation { duration: 100 } }

                                        Text {
                                            id: label
                                            anchors.centerIn: parent
                                            text: btn.modelData.text
                                            color: "#1d1d1f"
                                            font.family: "Noto Sans"
                                            font.pixelSize: 12
                                        }
                                        MouseArea {
                                            id: hover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: card.close(() => btn.modelData.invoke())
                                        }
                                    }
                                }
                            }

                            // ── 右:附件缩略图(没按钮时才出现) ──
                            Image {
                                visible: card.shownActions.length === 0 && card.attachSrc !== ""
                                source: card.attachSrc
                                Layout.preferredWidth: 56
                                Layout.preferredHeight: 56
                                Layout.alignment: Qt.AlignVCenter
                                // 必须 Fit 不能 Crop:截图是 16:9 的 4K 图,裁成正方形
                                // 只会显示中心一小块没有意义的区域,看不出截了什么。
                                // Fit 之后是一条横带,四角本来就透明,所以也不需要圆角遮罩。
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                sourceSize.width: 112
                                sourceSize.height: 112
                            }
                        }
                        }
                    }
                }
            }
        }
    }
