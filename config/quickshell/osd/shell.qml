//
// 音量 / 亮度 OSD
//
// 音量:直接监听 PipeWire,不需要改快捷键 —— 谁改的音量都会弹(wpctl / pavucontrol / 滚轮)。
// 亮度:由 scripts/brightness.sh 通过 IPC 推送,因为 DDC/CI 的当前值没法便宜地读到。
//   qs -c osd ipc call osd brightness <0-100>
//
// 配色抄自 waybar/style.css,图标沿用 config.jsonc 里的 Nerd Font 字形。
//
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Pipewire

ShellRoot {
    id: root

    // ── 状态 ────────────────────────────────────────────────────────────
    property string kind: "volume"   // "volume" | "brightness"
    property real   level: 0         // 0..1
    property bool   muted: false
    property bool   showing: false

    // PipeWire 启动时会枚举一遍节点并触发 volumeChanged,不静默会一开机就弹一次
    property bool armed: false

    readonly property var sink: Pipewire.defaultAudioSink

    // 不 track 的话 volume/muted 不会更新
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    Timer { interval: 1500; running: true; onTriggered: root.armed = true }

    // Hyprland.focusedMonitor 只在收到 focusedmon 事件时才赋值,shell 刚起来时是 null
    // (实测启动 3s 后仍为 undefined)。所以启动时用 hyprctl 播种一次,之后交给事件流。
    property string seedMonitor: ""
    readonly property string activeMonitor: Hyprland.focusedMonitor?.name ?? root.seedMonitor

    Process {
        running: true
        command: ["sh", "-c", "hyprctl monitors -j | jq -r '.[]|select(.focused)|.name'"]
        stdout: StdioCollector { onStreamFinished: root.seedMonitor = this.text.trim() }
    }
    Timer { id: hideTimer; interval: 1600; onTriggered: root.showing = false }

    function popup(k, lvl, m) {
        root.kind = k;
        root.level = Math.max(0, Math.min(1, lvl));
        root.muted = m === true;
        root.showing = true;
        hideTimer.restart();
    }

    // ── 音量:监听 PipeWire ──────────────────────────────────────────────
    Connections {
        target: root.sink?.audio ?? null

        function onVolumeChanged() {
            if (root.armed) root.popup("volume", root.sink.audio.volume, root.sink.audio.muted);
        }
        function onMutedChanged() {
            if (root.armed) root.popup("volume", root.sink.audio.volume, root.sink.audio.muted);
        }
    }

    // ── 亮度:等 brightness.sh 推 ────────────────────────────────────────
    IpcHandler {
        target: "osd"

        function brightness(pct: string): void {
            root.popup("brightness", parseFloat(pct) / 100, false);
        }
    }

    // ── 面板 ────────────────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData

            screen: modelData
            visible: root.showing && root.activeMonitor === modelData.name

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-osd"
            exclusionMode: ExclusionMode.Ignore
            anchors.bottom: true
            margins.bottom: 140
            implicitWidth: 320
            implicitHeight: 64
            color: "transparent"

            Rectangle {
                id: card
                anchors.fill: parent
                radius: 14
                color: "#f21c1c1e"                 // waybar 同色但更实:全局 blur 关着,OSD 要浮在任意窗口上
                border.color: "#12ffffff"          // waybar @border
                border.width: 1

                // 淡入 + 轻微上浮
                opacity: root.showing ? 1 : 0
                transform: Translate { y: root.showing ? 0 : 8
                                       Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } } }
                Behavior on opacity { NumberAnimation { duration: 140 } }

                Row {
                    anchors.centerIn: parent
                    spacing: 14

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: root.muted ? "#98989d" : "#f5f5f7"
                        text: {
                            if (root.kind === "brightness") return root.level > 0.5 ? "󰃠" : "󰃞";
                            if (root.muted) return "󰝟";
                            if (root.level < 0.01) return "󰕿";
                            return root.level < 0.5 ? "󰖀" : "󰕾";
                        }
                    }

                    Rectangle {                     // 进度条
                        anchors.verticalCenter: parent.verticalCenter
                        width: 190
                        height: 6
                        radius: 3
                        color: "#26ffffff"

                        Rectangle {
                            width: parent.width * root.level
                            height: parent.height
                            radius: parent.radius
                            color: root.muted ? "#98989d" : "#f5f5f7"
                            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 40
                        horizontalAlignment: Text.AlignRight
                        font.family: "Noto Sans"
                        font.pixelSize: 15
                        color: "#98989d"
                        text: Math.round(root.level * 100) + "%"
                    }
                }
            }
        }
    }
}
