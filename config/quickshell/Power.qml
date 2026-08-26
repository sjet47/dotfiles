//
// 电源菜单 —— 替代 wlogout
//
//   qs ipc call power toggle    绑在 SUPER + ALT + M
//   qs ipc call power open / hide
//
// 配色对齐 hyprlock:Noto Sans、前景 #f5f5f7、面板 #1c1c1e、边框白色 0.1 alpha。
//
// 动作沿用 wlogout 默认布局,但改了两处:
//   - 去掉 Hibernate。本机有 64G swap 但没配 resume(/sys/power/resume = 0:0),
//     按下去会写盘关机却无法恢复,等于丢会话。
//   - Logout 从 `loginctl terminate-user` 换成 `hyprctl dispatch exit`。会话是
//     start-hyprland 起的、不归 uwsm 管(wayland-wm@hyprland.service 是 inactive),
//     让合成器自己退出比杀掉整个 user 干净。
// Lock 保持 `loginctl lock-session`:走标准会话锁语义,由 hypridle 的 lock_cmd 拉起 hyprlock。
//
// 字母快捷键沿用 wlogout 默认(l/e/u/r/s),肌肉记忆不用改。
//
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: power

    required property string activeMonitor

    readonly property var actions: [
        { key: "l", icon: "󰌾", label: "锁屏", danger: false, cmd: ["loginctl", "lock-session"] },
        { key: "e", icon: "󰍃", label: "注销", danger: false, cmd: ["hyprctl", "dispatch", "exit"] },
        { key: "u", icon: "󰤄", label: "挂起", danger: false, cmd: ["systemctl", "suspend"] },
        { key: "r", icon: "󰜉", label: "重启", danger: true,  cmd: ["systemctl", "reboot"] },
        { key: "s", icon: "󰐥", label: "关机", danger: true,  cmd: ["systemctl", "poweroff"] }
    ]

    property bool open: false
    property bool rendered: false      // 面板是否还在;关闭时要等淡出播完才撤掉
    property int  selected: 0

    onOpenChanged: {
        if (power.open) {
            power.selected = 0;
            power.rendered = true;
        } else {
            fadeOut.restart();
        }
    }

    Timer { id: fadeOut; interval: 180; onTriggered: power.rendered = false }

    function run(i) {
        const a = power.actions[i];
        if (!a) return;
        power.open = false;
        Quickshell.execDetached(a.cmd);
    }

    IpcHandler {
        target: "power"

        // 不能叫 show:`qs ipc` 有同名子命令,`qs ipc call power show` 会被当成
        // introspection 打印函数列表,函数本身根本调不到。
        function open(): string   { power.open = true;  return "shown"; }
        function hide(): string   { power.open = false; return "hidden"; }
        function toggle(): string { power.open = !power.open; return power.open ? "shown" : "hidden"; }
    }

    Variants {
        model: Quickshell.screens.filter(s => s.name === power.activeMonitor)

        PanelWindow {
            id: panel
            required property var modelData

            screen: modelData
            visible: power.rendered

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-power"
            // 电源菜单必须能吃键盘(Esc / 字母快捷键 / 方向键),这是它和 OSD、通知
            // 最大的不同 —— 那两个都是 keyboardFocus: None。
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            // 铺满整屏(盖住 waybar),所以不参与独占区计算
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            // 遮罩:点空白处关闭
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                // 0.45 压不住背后的亮色窗口(实测浏览器正文仍清晰可读),没有模态感
                opacity: power.open ? 0.72 : 0
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                MouseArea { anchors.fill: parent; onClicked: power.open = false }
            }

            FocusScope {
                anchors.fill: parent
                focus: true

                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Escape) {
                        power.open = false; event.accepted = true; return;
                    }
                    // 只用方向键导航:vim 风格的 h/l 会和 l=锁屏 的字母快捷键撞车
                    if (event.key === Qt.Key_Left) {
                        power.selected = (power.selected - 1 + power.actions.length) % power.actions.length;
                        event.accepted = true; return;
                    }
                    if (event.key === Qt.Key_Right) {
                        power.selected = (power.selected + 1) % power.actions.length;
                        event.accepted = true; return;
                    }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        power.run(power.selected); event.accepted = true; return;
                    }
                    const i = power.actions.findIndex(a => a.key === (event.text ?? "").toLowerCase());
                    if (i >= 0) { power.run(i); event.accepted = true; }
                }

                // 一张卡片把 5 个按钮收拢:由它承担"面"的存在感,按钮本身做轻、
                // 靠选中态发亮 —— 否则 5 个各自带底色的方块散在屏幕中间很零碎。
                Rectangle {
                    id: sheet
                    anchors.centerIn: parent
                    width: row.width + 56
                    height: 28 + row.height + 16 + hint.height + 18
                    radius: 30
                    color: "#f21c1c1e"   // 0.88 时背后窗口的文字仍可辨,压到 0.95
                    border { width: 1; color: "#1affffff" }   // hyprlock outer_color 同款

                    opacity: power.open ? 1 : 0
                    scale: power.open ? 1 : 0.94
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                    Row {
                        id: row
                        anchors { top: parent.top; topMargin: 28
                                  horizontalCenter: parent.horizontalCenter }
                        spacing: 12

                        Repeater {
                            model: power.actions

                            delegate: Rectangle {
                                id: btn
                                required property var modelData
                                required property int index

                                readonly property bool hot: power.selected === btn.index || hover.containsMouse

                                width: 124
                                height: 124
                                radius: 20
                                color: btn.hot ? (btn.modelData.danger ? "#33ff453a" : "#26ffffff")
                                               : "#0dffffff"
                                border.width: 1
                                border.color: btn.hot ? (btn.modelData.danger ? "#66ff453a" : "#33ffffff")
                                                      : "transparent"
                                Behavior on color        { ColorAnimation { duration: 120 } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                MouseArea {
                                    id: hover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: power.selected = btn.index
                                    onClicked: power.run(btn.index)
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: btn.modelData.icon
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 38
                                        color: btn.hot && btn.modelData.danger ? "#ff453a" : "#f5f5f7"
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: btn.modelData.label
                                        font.family: "Noto Sans"
                                        font.pixelSize: 14
                                        color: "#f5f5f7"
                                        opacity: btn.hot ? 1 : 0.75
                                        Behavior on opacity { NumberAnimation { duration: 120 } }
                                    }
                                    // 快捷键贴在自己按钮下面,而不是在底部提示里把标签重复一遍
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: btn.modelData.key.toUpperCase()
                                        font.family: "Noto Sans"
                                        font.pixelSize: 11
                                        color: "#f5f5f7"
                                        opacity: btn.hot ? 0.6 : 0.35
                                        Behavior on opacity { NumberAnimation { duration: 120 } }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        id: hint
                        anchors { bottom: parent.bottom; bottomMargin: 18
                                  horizontalCenter: parent.horizontalCenter }
                        text: "← → 选择   ·   Enter 确认   ·   Esc 取消"
                        font.family: "Noto Sans"
                        font.pixelSize: 12
                        color: "#f5f5f7"
                        opacity: 0.4
                    }
                }
            }
        }
    }
}
