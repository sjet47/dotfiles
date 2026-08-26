//
// 音量 / 亮度 OSD
//
// 音量:直接监听 PipeWire,不需要改快捷键 —— 谁改的音量都会弹(wpctl / pavucontrol / 滚轮)。
// 麦克风:同理监听 defaultAudioSource 的 muted,给 XF86AudioMicMute 补上视觉反馈。
// 亮度:由 scripts/brightness.sh 通过 IPC 推送,因为 DDC/CI 的当前值没法便宜地读到。
//   qs ipc call osd brightness <0-100>
//
// 配色抄自 waybar/style.css,图标沿用 config.jsonc 里的 Nerd Font 字形。
//
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

Scope {
    id: osd

    required property string activeMonitor

    property string kind: "volume"   // "volume" | "brightness" | "mic"
    property real   level: 0         // 0..1
    property bool   muted: false
    property bool   showing: false

    // PipeWire 启动时会枚举一遍节点并触发 volumeChanged,不静默会一开机就弹一次
    property bool armed: false

    readonly property var sink:   Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // 不 track 的话 volume/muted 不会更新
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    Timer { interval: 1500; running: true; onTriggered: osd.armed = true }
    Timer { id: hideTimer; interval: 1600; onTriggered: osd.showing = false }

    function popup(k, lvl, m) {
        osd.kind = k;
        osd.level = Math.max(0, Math.min(1, lvl));
        osd.muted = m === true;
        osd.showing = true;
        hideTimer.restart();
    }

    Connections {
        target: osd.sink?.audio ?? null

        function onVolumeChanged() {
            if (osd.armed) osd.popup("volume", osd.sink.audio.volume, osd.sink.audio.muted);
        }
        function onMutedChanged() {
            if (osd.armed) osd.popup("volume", osd.sink.audio.volume, osd.sink.audio.muted);
        }
    }

    // 麦克风:只听 muted。XF86AudioMicMute 绑的就是 set-mute,而音量变化可能来自
    // 应用自动增益之类的后台行为,跟着弹会很吵。
    Connections {
        target: osd.source?.audio ?? null

        function onMutedChanged() {
            if (osd.armed) osd.popup("mic", osd.source.audio.volume, osd.source.audio.muted);
        }
    }

    IpcHandler {
        target: "osd"

        function brightness(pct: string): void {
            osd.popup("brightness", parseFloat(pct) / 100, false);
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData

            screen: modelData
            visible: osd.showing && osd.activeMonitor === modelData.name

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-osd"
            exclusionMode: ExclusionMode.Ignore   // OSD 悬浮在底部中间,不参与独占区计算
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
                opacity: osd.showing ? 1 : 0
                transform: Translate { y: osd.showing ? 0 : 8
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
                        color: osd.muted ? "#98989d" : "#f5f5f7"
                        text: {
                            if (osd.kind === "brightness") return osd.level > 0.5 ? "󰃠" : "󰃞";
                            if (osd.kind === "mic") return osd.muted ? "󰍭" : "󰍬";
                            if (osd.muted) return "󰝟";
                            if (osd.level < 0.01) return "󰕿";
                            return osd.level < 0.5 ? "󰖀" : "󰕾";
                        }
                    }

                    Rectangle {                     // 进度条
                        anchors.verticalCenter: parent.verticalCenter
                        width: 190
                        height: 6
                        radius: 3
                        color: "#26ffffff"

                        Rectangle {
                            width: parent.width * osd.level
                            height: parent.height
                            radius: parent.radius
                            color: osd.muted ? "#98989d" : "#f5f5f7"
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
                        text: Math.round(osd.level * 100) + "%"
                    }
                }
            }
        }
    }
}
