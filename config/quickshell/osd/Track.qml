//
// 曲目切换 OSD。
//
// 和音量/亮度那个 OSD 是同一套观感(底部居中、淡入上浮、1.6s 收),区别是内容多一张封面。
// 触发条件只有一个:**当前播放器换了曲目**。不跟播放/暂停 —— 按暂停时弹一张卡片属于噪音。
//
// 播放器的选取(`current`)要处理两件事:
//   1. 本机同时存在 org.mpris.MediaPlayer2.{mpv,playerctld} 两个源,**playerctld 是聚合代理**,
//      它会把别的播放器的状态再镜像一遍。不排掉的话换一次曲目会弹两张一模一样的卡。
//      只在没有真实播放器时才拿它兜底。
//   2. 多个真实播放器时优先正在播放的那个。
//
// IPC(调试用,不用真去切歌):
//   qs ipc call track preview
//
// 注意函数不能叫 show(README 坑 15:会被 `qs ipc` 的同名子命令吃掉)。
//
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris

Scope {
    id: track

    required property string activeMonitor

    property bool showing: false
    property string title: ""
    property string artist: ""
    property string art: ""

    // 启动时 MPRIS 会把已有播放器枚举一遍并触发一次 trackTitleChanged,
    // 不静默就会一开机弹一张(同 Osd.qml 的 armed)
    property bool armed: false

    readonly property var players: Mpris.players?.values ?? []

    readonly property var current: {
        const real = track.players.filter(p => !/playerctld/i.test(p.dbusName ?? ""));
        const pool = real.length > 0 ? real : track.players;   // 没有真实播放器时才用代理兜底
        return pool.find(p => p.isPlaying) ?? pool[0] ?? null;
    }

    Timer { interval: 1500; running: true; onTriggered: track.armed = true }
    Timer { id: hideTimer; interval: 2600; onTriggered: track.showing = false }

    function popup(): void {
        const p = track.current;
        if (!p || !p.trackTitle) return;
        track.title = p.trackTitle;
        track.artist = [p.trackArtist, p.trackAlbum].filter(s => s).join(" — ");
        track.art = p.trackArtUrl ?? "";
        track.showing = true;
        hideTimer.restart();
    }

    Connections {
        target: track.current
        function onTrackTitleChanged() { if (track.armed) track.popup(); }
    }

    // 播放器本身换了(比如从 Chrome 切到 mpv):上面的 Connections 不会为这次切换触发,
    // 这里补一下。只在新播放器确实在放东西时弹。
    onCurrentChanged: if (track.armed && track.current?.isPlaying) track.popup()

    IpcHandler {
        target: "track"
        function preview(): string {
            track.popup();
            return track.showing ? track.title : "(无正在播放的曲目)";
        }
    }

    Variants {
        model: Quickshell.screens.filter(s => s.name === track.activeMonitor)

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: track.showing

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-track"
            exclusionMode: ExclusionMode.Ignore
            anchors.bottom: true
            margins.bottom: 140
            implicitWidth: 420
            implicitHeight: 84
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: "#f21c1c1e"
                border.color: "#12ffffff"
                border.width: 1

                opacity: track.showing ? 1 : 0
                transform: Translate { y: track.showing ? 0 : 8
                                       Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } } }
                Behavior on opacity { NumberAnimation { duration: 140 } }

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // 封面。限制解码尺寸(README 坑 13):有的播放器塞的是整张专辑大图
                    Rectangle {
                        width: 60
                        height: 60
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 8
                        color: "#1affffff"
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: track.art
                            visible: track.art !== ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 120
                            sourceSize.height: 120
                            smooth: true
                        }

                        Text {                                   // 没封面时的占位
                            anchors.centerIn: parent
                            visible: track.art === ""
                            text: "\udb81\udd1f"          // U+F051F nf-md-music
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 24
                            color: "#98989d"
                        }
                    }

                    Column {
                        width: parent.width - 72
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            width: parent.width
                            text: track.title
                            elide: Text.ElideRight
                            color: "#f5f5f7"
                            font.family: "Noto Sans"
                            font.pixelSize: 16
                            renderType: Text.NativeRendering
                            font.hintingPreference: Font.PreferVerticalHinting
                        }

                        Text {
                            width: parent.width
                            text: track.artist
                            elide: Text.ElideRight
                            visible: track.artist !== ""
                            color: "#98989d"
                            font.family: "Noto Sans"
                            font.pixelSize: 13
                            renderType: Text.NativeRendering
                            font.hintingPreference: Font.PreferVerticalHinting
                        }
                    }
                }
            }
        }
    }
}
