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
// 行为对齐 config/mako/config:浅色卡片、右上角、宽 420、默认 5s、
// critical 不自动消失且红边、免打扰时只放行 notify-send、截图通知用大图。
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
            margins { top: 20; right: 20 }      // mako outer-margin=20
            implicitWidth: 420                  // mako width=420
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
                width: parent.width
                spacing: 10

                // 上方卡片被摘掉后,下方靠 move 过渡平滑上移(默认是瞬间跳位)
                move: Transition { NumberAnimation { properties: "y"; duration: 220; easing.type: Easing.OutCubic } }
                add:  Transition { NumberAnimation { properties: "y"; duration: 220; easing.type: Easing.OutCubic } }

                Repeater {
                    model: popupModel

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        readonly property var n: card.modelData

                        // 截图通知带 -i <图片路径>,mako 里给它开了 max-icon-size=80
                        readonly property bool bigImage: /Screenshot|截图/.test(card.n.summary ?? "")
                        readonly property int  iconSize: card.bigImage ? 80 : 32

                        // 退场:向右滑出 + 淡出。动画期间 delegate 必须还活着,
                        // 所以真正从 model 摘掉要等 onFinished,否则一 drop 就销毁,没机会播。
                        transform: Translate { id: slide }

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

                        // act 是动画结束后要做的事(expire / dismiss / invoke)
                        function close(act) {
                            if (exitAnim.running) return;
                            exitAnim.act = act ?? null;
                            exitAnim.start();
                        }

                        readonly property string pic: {
                            if (card.n.image) return card.n.image;
                            const i = card.n.appIcon ?? "";
                            if (i === "") return "";
                            return (i.startsWith("/") || i.startsWith("file:")) ? i : Quickshell.iconPath(i, true);
                        }

                        width: parent.width
                        implicitHeight: row.implicitHeight + 20   // mako padding=10,15 的上下部分
                        radius: 12                                // mako border-radius=12
                        // mako 的 #f5f5f7d9 是 RRGGBBAA,而 Qt 的八位色是 AARRGGBB ——
                        // 照抄字符串会被读成 96% 不透明的米黄色,要换序。
                        color: "#d9f5f5f7"                        // = mako background-color
                        border.width: 1                           // mako border-size=1
                        border.color: card.n.urgency === NotificationUrgency.Critical ? "#ff453a"
                                    : card.n.urgency === NotificationUrgency.Low      ? "#e5e5ea"
                                    : "#d2d2d7"

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
                                // 左键触发 default action(截图的"标注"、录屏的"打开"都靠它)
                                card.close(function (n) {
                                    const def = (n.actions ?? []).find(a => a.identifier === "default");
                                    if (def) def.invoke(); else n.dismiss();
                                });
                            }
                        }

                        RowLayout {
                            id: row
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                                      leftMargin: 15; rightMargin: 15 }   // mako padding 的左右部分
                            spacing: 12

                            Image {
                                visible: card.pic !== ""
                                source: card.pic
                                Layout.preferredWidth: card.iconSize
                                Layout.preferredHeight: card.iconSize
                                Layout.alignment: Qt.AlignVCenter
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                // 截图通知传的是整张 4K PNG,不限制就按原分辨率解进内存
                                sourceSize.width: card.iconSize * 2
                                sourceSize.height: card.iconSize * 2
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: card.n.summary ?? ""
                                    color: "#1d1d1f"                    // mako text-color
                                    font.family: "Noto Sans"
                                    font.pixelSize: 14                  // mako font=sans-serif 14px
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: (card.n.body ?? "") !== ""
                                    // body 里是真换行符(0a,xxd 实测),而 StyledText 是 HTML 语义会把它
                                    // 折叠成空格,所以要换成 <br/>。mako 是渲染成换行的,对齐它。
                                    text: (card.n.body ?? "").replace(/\n/g, "<br/>")
                                    color: "#1d1d1f"
                                    font.family: "Noto Sans"
                                    font.pixelSize: 14
                                    textFormat: Text.StyledText          // 通知规范的 Pango 子集,mako 亦然
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 6
                                    elide: Text.ElideRight
                                }

                                // 非 default 的 action 画成按钮 —— mako 做不到,只能配快捷键
                                Flow {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 4
                                    spacing: 6
                                    visible: actions.count > 0

                                    Repeater {
                                        id: actions
                                        model: (card.n.actions ?? []).filter(a => a.identifier !== "default")

                                        delegate: Rectangle {
                                            id: btn
                                            required property var modelData
                                            width: label.implicitWidth + 18
                                            height: label.implicitHeight + 8
                                            radius: 6
                                            color: hover.containsMouse ? "#e0e0e5" : "#ebebf0"
                                            border { width: 1; color: "#d2d2d7" }

                                            Text {
                                                id: label
                                                anchors.centerIn: parent
                                                text: btn.modelData.text
                                                color: "#1d1d1f"
                                                font.family: "Noto Sans"
                                                font.pixelSize: 13
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
                            }
                        }
                    }
                }
            }
        }
    }
}
