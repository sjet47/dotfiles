//
// 通知守护 —— 替代 mako
//
// 独立于 osd 那份配置跑(qs -c notifications),两者互不影响:通知崩了不会带走 OSD。
//
// 对外接口(waybar 的 custom/notifications 模块在用):
//   qs -c notifications ipc call notif dndToggle   切免打扰,返回 on/off
//   qs -c notifications ipc call notif dndStatus   查免打扰
//   qs -c notifications ipc call notif history     历史记录 JSON
//
// 行为对齐 config/mako/config:浅色卡片、右上角、宽 420、默认 5s、
// critical 不自动消失且红边、免打扰时只放行 notify-send、截图通知用大图。
//
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications

ShellRoot {
    id: root

    property bool  dnd: false
    property var   popups: []      // 正在显示的 Notification 对象
    property var   log: []         // 历史(纯数据,通知对象销毁后仍在)
    readonly property int maxLog: 50

    // 与 osd 那份同样的处理:focusedMonitor 启动时为 null,先用 hyprctl 播种
    property string seedMonitor: ""
    readonly property string activeMonitor: Hyprland.focusedMonitor?.name ?? root.seedMonitor

    Process {
        running: true
        command: ["sh", "-c", "hyprctl monitors -j | jq -r '.[]|select(.focused)|.name'"]
        stdout: StdioCollector { onStreamFinished: root.seedMonitor = this.text.trim() }
    }

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

            root.log = [{
                appName: n.appName, summary: n.summary, body: n.body,
                urgency: n.urgency, time: Date.now()
            }].concat(root.log).slice(0, root.maxLog);

            // 免打扰:只放行 notify-send(和 mako 的 [mode=do-not-disturb app-name=notify-send] 一致)
            if (root.dnd && n.appName !== "notify-send") return;

            root.popups = [n].concat(root.popups);
        }
    }

    function drop(n) {
        root.popups = root.popups.filter(x => x !== n);
    }

    IpcHandler {
        target: "notif"

        function dndToggle(): string { root.dnd = !root.dnd; return root.dnd ? "on" : "off"; }
        function dndStatus(): string { return root.dnd ? "on" : "off"; }
        function history(): string   { return JSON.stringify(root.log); }

        // 对应 makoctl invoke / makoctl dismiss --all
        function invoke(): string {
            const n = root.popups[0];
            if (!n) return "none";
            const def = (n.actions ?? []).find(a => a.identifier === "default");
            root.drop(n);
            if (!def) { n.dismiss(); return "dismissed"; }
            def.invoke();
            return "invoked";
        }
        function dismissAll(): string {
            const c = root.popups.length;
            root.popups.forEach(n => n.dismiss());
            root.popups = [];
            return String(c);
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData

            screen: modelData
            visible: root.popups.length > 0 && root.activeMonitor === modelData.name

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-notifications"
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; right: true }
            margins { top: 20; right: 20 }      // mako outer-margin=20
            implicitWidth: 420                  // mako width=420
            implicitHeight: Math.max(1, stack.implicitHeight)
            color: "transparent"

            Column {
                id: stack
                width: parent.width
                spacing: 10

                Repeater {
                    model: root.popups

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        readonly property var n: card.modelData

                        // 截图通知带 -i <图片路径>,mako 里给它开了 max-icon-size=80
                        readonly property bool bigImage: /Screenshot|截图/.test(card.n.summary ?? "")
                        readonly property int  iconSize: card.bigImage ? 80 : 32

                        readonly property string pic: {
                            if (card.n.image) return card.n.image;
                            const i = card.n.appIcon ?? "";
                            if (i === "") return "";
                            return (i.startsWith("/") || i.startsWith("file:")) ? i : Quickshell.iconPath(i, true);
                        }

                        width: parent.width
                        implicitHeight: row.implicitHeight + 20   // mako padding=10,15 的上下部分
                        radius: 12                                // mako border-radius=12
                        color: "#f5f5f7d9"                        // mako background-color
                        border.width: 1                           // mako border-size=1
                        border.color: card.n.urgency === NotificationUrgency.Critical ? "#ff453a"
                                    : card.n.urgency === NotificationUrgency.Low      ? "#e5e5ea"
                                    : "#d2d2d7"

                        // critical 不自动消失(mako 的 [urgency=critical] default-timeout=0)
                        Timer {
                            running: card.n.urgency !== NotificationUrgency.Critical
                            interval: card.n.expireTimeout > 0 ? card.n.expireTimeout : 5000
                            onTriggered: { root.drop(card.n); card.n.expire(); }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function (mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    root.drop(card.n); card.n.dismiss();
                                    return;
                                }
                                // 左键触发 default action(截图的"标注"、录屏的"打开"都靠它)
                                const def = (card.n.actions ?? []).find(a => a.identifier === "default");
                                root.drop(card.n);
                                if (def) def.invoke(); else card.n.dismiss();
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
                                // 截图通知传的是整张 4K PNG。不限制解码尺寸的话 Qt 会按原始
                                // 分辨率解到内存里且不随弹窗消失释放(实测基线 184MB 涨到 293MB),
                                // 而每次截图都会发一条,会持续累积。按显示尺寸解码即可。
                                sourceSize.width: card.iconSize * 2
                                sourceSize.height: card.iconSize * 2
                                cache: false
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
                                    // body 里是真换行符(0a,实测 xxd 确认),而 StyledText 是 HTML
                                    // 语义会把它折叠成空格,所以要换成 <br/>。mako 是渲染成换行的,对齐它。
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
                                    visible: repeater.count > 0

                                    Repeater {
                                        id: repeater
                                        model: (card.n.actions ?? []).filter(a => a.identifier !== "default")

                                        delegate: Rectangle {
                                            required property var modelData
                                            width: label.implicitWidth + 18
                                            height: label.implicitHeight + 8
                                            radius: 6
                                            color: hover.containsMouse ? "#e0e0e5" : "#ebebf0"
                                            border { width: 1; color: "#d2d2d7" }

                                            Text {
                                                id: label
                                                anchors.centerIn: parent
                                                text: parent.modelData.text
                                                color: "#1d1d1f"
                                                font.family: "Noto Sans"
                                                font.pixelSize: 13
                                            }
                                            MouseArea {
                                                id: hover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: { root.drop(card.n); parent.modelData.invoke(); }
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
