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
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
    id: notif

    // 焦点屏 —— 这里只当兜底用,通知本身不跟焦点走
    required property string activeMonitor

    // 通知固定在主屏。OSD / 电源菜单跟着焦点是对的(反馈应该出现在你正看的屏上),
    // 但通知跟着焦点跳会很烦 —— 切个屏正在读的通知就跑了。
    // 主屏不在(拔了、改名)时回退到焦点屏,否则通知会静默消失。
    property string pinnedMonitor: "DP-1"

    readonly property string targetMonitor: {
        if (notif.pinnedMonitor !== ""
            && Quickshell.screens.some(s => s.name === notif.pinnedMonitor))
            return notif.pinnedMonitor;
        return notif.activeMonitor;
    }

    property bool  dnd: false
    property var   popups: []      // 正在显示的 Notification 对象
    property var   log: []         // 历史(纯数据,通知对象销毁后仍在)
    readonly property int maxLog: 50

    // 同一时刻只允许一张卡片打开菜单。菜单画在卡片外面,要靠它来放开输入遮罩。
    property var openMenuCard: null

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
        model: Quickshell.screens.filter(s => s.name === notif.targetMonitor)

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
            // 菜单是画在卡片外面的,落在 stack 区域之外就点不到 —— 所以菜单打开时
            // 干脆取消遮罩、整块面板收输入,顺带得到"点击别处关闭菜单"。
            mask: notif.openMenuCard ? null : stackRegion
            Region { id: stackRegion; item: stack }

            // 菜单打开时,点空白处关掉它
            MouseArea {
                anchors.fill: parent
                enabled: notif.openMenuCard !== null
                onClicked: notif.openMenuCard = null
            }
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
                        // action 收在右下角 Options 的弹出菜单里,不占卡片布局 ——
                        // 所以缩略图不再和按钮抢右槽,两者可以同时出现。
                        // 用 HoverHandler 而不是 MouseArea.containsMouse:
                        // 子 MouseArea 会从父的手里抢走 hover,而且两者的状态更新有先后 ——
                        // 光标离开 Options 那一帧 opt 已变 false、card 还没变 true,
                        // 并集在那一帧为假,按钮就闪一下。实测日志里是
                        //   HOVER opt=false card=false   ← 缝隙
                        //   HOVER card=true
                        // HoverHandler 报告的是"指针在本 item 或任意子项之上",没有这个缝隙。
                        readonly property bool hovered: cardHover.hovered

                        HoverHandler { id: cardHover }
                        readonly property bool menuOpen: notif.openMenuCard === card

                        // 菜单画在卡片**外面**(下方),而卡片之间是 Column 的兄弟节点 ——
                        // menu 内部那个 z: 100 只在本卡片内排序,压不住后面的卡片,
                        // 于是菜单会被下一条通知盖住。要抬就得抬整张卡片。
                        // 同时只有一张卡片能开菜单(notif.openMenuCard),不会互相打架。
                        z: card.menuOpen ? 1 : 0

                        width: parent.width
                        // 高度跟着内容走,正文最多 4 行 —— 这是对着 macOS 实机截图定的:
                        // 单行正文的横幅很扁,多行的明显长,并不是定高。下限 56 保证
                        // 只有标题时也不会瘦成一条。
                        implicitHeight: Math.max(56, layout.implicitHeight)
                        radius: 18
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
                            // 悬停或菜单打开时停表 —— macOS 悬停也会保住通知,
                            // 否则展开到一半通知就没了。离开后 running 由假变真会重启计时。
                            running: card.n.urgency !== NotificationUrgency.Critical
                                     && !card.hovered && !card.menuOpen
                            interval: card.n.expireTimeout > 0 ? card.n.expireTimeout : 5000
                            onTriggered: card.close(n => n.expire())
                        }

                        MouseArea {
                            id: cardMouse
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

                        ColumnLayout {
                            id: layout
                            anchors.fill: parent
                            spacing: 0

                        RowLayout {
                            id: row
                            Layout.fillWidth: true

                            // 内容整层淡出,给 Options 让位。挂在 row 上而不是正文上 ——
                            // 右槽的附件缩略图和左边的图标同样会压在按钮底下,
                            // 只遮正文的话有图时按钮照样没法读。
                            layer.enabled: optBtn.visible
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: fadeMask
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1.0
                            }
                            Layout.leftMargin: 12
                            Layout.rightMargin: 12
                            Layout.topMargin: 8
                            Layout.bottomMargin: 8
                            spacing: 12

                            // ── 左:应用图标 ──
                            // 圆角遮罩裁剪。注意这对不同图标效果不同:
                            //   飞书 —— 自带白色圆角方底,本来就是圆的,遮罩基本不改变什么
                            //   kitty —— 猫头,四周全透明,没有角可裁,遮罩等于没加
                            // 真正生效的是那些直角不透明方图。
                            Item {
                                visible: card.appIconSrc !== ""
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                Layout.alignment: Qt.AlignVCenter

                                Image {
                                    id: iconImg
                                    anchors.fill: parent
                                    source: card.appIconSrc
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    sourceSize.width: 80
                                    sourceSize.height: 80
                                    visible: false          // 由 MultiEffect 画
                                }
                                Item {
                                    id: iconMask
                                    anchors.fill: parent
                                    layer.enabled: true
                                    layer.smooth: true
                                    layer.samples: 4          // 遮罩自身要 MSAA,否则圆角是硬阶梯
                                    visible: false
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 9
                                        color: "black"
                                        antialiasing: true
                                    }
                                }
                                MultiEffect {
                                    anchors.fill: parent
                                    source: iconImg
                                    maskEnabled: true
                                    maskSource: iconMask
                                    // 默认是按 alpha 硬切,边缘只有一个像素的过渡 → 锯齿。
                                    // 抬高阈值再给足 spread,让它吃满遮罩自带的抗锯齿渐变。
                                    maskThresholdMin: 0.5
                                    maskSpreadAtMin: 1.0
                                }
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
                                    id: bodyText
                                    Layout.fillWidth: true
                                    visible: (card.n.body ?? "") !== ""
                                    // body 里是真换行符(0a),StyledText 是 HTML 语义会折叠成空格
                                    text: (card.n.body ?? "").replace(/\n/g, "<br/>")
                                    color: "#1d1d1f"
                                    font.family: "Noto Sans"
                                    font.pixelSize: 14
                                    textFormat: Text.StyledText
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 4      // macOS 实机截图是第 4 行处省略号截断
                                    elide: Text.ElideRight
                                }
                            }

                            // ── 右:附件缩略图(没按钮时才出现) ──
                            Image {
                                visible: card.attachSrc !== ""
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

                        // ── 悬停才出现的覆盖层(不占布局,浮在正文上) ──

                        // Options 的擦除遮罩源(白=保留,透明=擦掉)。
                        //
                        // 要的是"以按钮为中心向外 alpha 0→1",用两道线性渐变叠出来:
                        //   横向 —— 左白右透   纵向 —— 上白下透
                        // 普通叠加是 over 合成,alpha 取的是**并集**(a2+a1(1-a2)),
                        // 所以只有"既靠右又靠下"的那个角两道都透明 —— 正好是个软边角洞。
                        // 省掉 QtQuick.Shapes 的 RadialGradient,效果上没差。
                        //
                        // 止点按按钮的实际位置算(row 的右/下边缘和按钮是对齐的:
                        // row 的左右 margin 12 = 按钮 rightMargin,上下 8 = bottomMargin),
                        // 不用比例硬编 —— 卡片高度随正文行数变,写死比例在单行卡片上会整片擦掉。
                        readonly property real fadeX0: Math.max(0, (row.width - optBtn.width - 60) / Math.max(1, row.width))
                        readonly property real fadeX1: Math.min(1, Math.max(card.fadeX0 + 0.01, (row.width - optBtn.width - 4) / Math.max(1, row.width)))
                        readonly property real fadeY0: Math.max(0, (row.height - optBtn.height - 26) / Math.max(1, row.height))
                        readonly property real fadeY1: Math.min(1, Math.max(card.fadeY0 + 0.01, (row.height - optBtn.height - 2) / Math.max(1, row.height)))

                        Item {
                            id: fadeMask
                            visible: false
                            layer.enabled: true
                            width: row.width
                            height: row.height

                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: card.fadeX0; color: "white" }
                                    GradientStop { position: card.fadeX1; color: "transparent" }
                                }
                            }
                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    GradientStop { position: card.fadeY0; color: "white" }
                                    GradientStop { position: card.fadeY1; color: "transparent" }
                                }
                            }
                        }

                        // 右下角 Options —— 浮在正文上,不撑开卡片
                        Rectangle {
                            id: optBtn
                            visible: card.actionList.length > 0 && (card.hovered || card.menuOpen)
                            anchors { right: parent.right; bottom: parent.bottom
                                      rightMargin: 12; bottomMargin: 8 }
                            width: optLabel.implicitWidth + 22
                            height: 24
                            radius: 6
                            // 背后的内容已经被遮罩擦干净了,按钮不需要靠不透明度去挣可读性,
                            // 所以只用 10% 的正文色轻轻压暗(实测卡片 213 / 按钮 194)。
                            color: optMouse.containsMouse || card.menuOpen ? "#2e1d1d1f" : "#1a1d1d1f"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                id: optLabel
                                anchors.centerIn: parent
                                text: "Options \u2304"
                                color: "#1d1d1f"
                                font.family: "Noto Sans"
                                font.pixelSize: 12
                            }
                            MouseArea {
                                id: optMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: notif.openMenuCard = card.menuOpen ? null : card
                            }
                        }

                        // ── 弹出菜单:画在卡片下方、右对齐 ──
                        Rectangle {
                            id: menu
                            visible: card.menuOpen
                            z: 100          // 压住下面的卡片
                            anchors { right: parent.right; top: parent.bottom
                                      rightMargin: 8; topMargin: 6 }
                            width: Math.max(150, menuCol.implicitWidth + 24)
                            height: menuCol.implicitHeight + 8
                            radius: 8
                            // 跟卡片同一种材质:同底色、**同透明度**。
                            // 原来是 #f2f5f5f7(95% 不透明)+ 黑色描边 —— 比胶囊又亮又实,
                            // 看着是另一块面板贴上来的。菜单画在卡片外面、直接压桌面,
                            // 所以用卡片的 #d9f5f5f7 合成出来就和胶囊一模一样。
                            color: "#d9f5f5f7"
                            border { width: 1; color: "#d2d2d7" }

                            ColumnLayout {
                                id: menuCol
                                anchors { left: parent.left; right: parent.right
                                          verticalCenter: parent.verticalCenter }
                                spacing: 0

                                Repeater {
                                    model: card.actionList

                                    delegate: Rectangle {
                                        id: mi
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 28
                                        Layout.leftMargin: 4
                                        Layout.rightMargin: 4
                                        radius: 5
                                        color: miMouse.containsMouse ? "#0a84ff" : "transparent"

                                        Text {
                                            anchors { left: parent.left; leftMargin: 10
                                                      verticalCenter: parent.verticalCenter }
                                            text: mi.modelData.text
                                            color: miMouse.containsMouse ? "#ffffff" : "#1d1d1f"
                                            font.family: "Noto Sans"
                                            font.pixelSize: 13
                                        }
                                        MouseArea {
                                            id: miMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                notif.openMenuCard = null;
                                                card.close(() => mi.modelData.invoke());
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
