//
// Claude 用量(= waybar 的 custom/claude),数据源仍是 scripts/claude-usage.sh。
//
// 脚本是**常驻进程**,每探测一次就往 stdout 打一行 JSON(15 分钟一轮,失败时 60s 快速重试),
// 所以这里用 SplitParser 按行收,而不是像 Stock 那样定时重跑。
//
// 左键立即刷新:迁移前是 `pkill -USR1 -f 'scripts/claude-usage.sh$'`,现在直接对自己
// 拉起的那个进程发信号(Process.signal),不用再靠命令行匹配去猜是哪个进程。
//
// 图标是官方星芒 SVG。waybar 那边只能走 CSS background-image,而 GTK 不把 currentColor
// 传给背景图,所以 SVG 里的 fill 是写死的 #f5f5f7 —— 这里也就跟着沿用同一个文件。
//
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

BarItem {
    id: root

    readonly property string script: Qt.resolvedUrl("scripts/claude-usage.sh").toString().replace("file://", "")

    property string label: ""
    property string tip: ""
    property string cls: ""                          // "" | "warning" | "critical"

    tooltipText: root.tip
    onClicked: b => {
        if (b === Qt.RightButton) Quickshell.execDetached(["xdg-open", "https://claude.ai/settings/usage"]);
        else if (proc.processId > 0) proc.signal(10);   // SIGUSR1 = 立即重探
    }

    Process {
        id: proc
        command: [root.script]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const j = JSON.parse(line);
                    root.label = j.text ?? "";
                    root.tip = j.tooltip ?? "";
                    root.cls = j.class ?? "";
                } catch (e) {
                }
            }
        }
    }

    Image {
        anchors.verticalCenter: parent.verticalCenter
        width: 15                                    // background-size: 15px 15px
        height: 15
        sourceSize.width: 30
        sourceSize.height: 30
        source: Qt.resolvedUrl("icons/claude.svg")
        smooth: true
    }

    Text {
        text: root.label
        font.family: Theme.font
        renderType: Text.NativeRendering
        font.hintingPreference: Theme.hinting
        font.pixelSize: Theme.fontSize
        font.features: ({ "tnum": 1 })
        color: root.cls === "critical" ? Theme.critical
               : root.cls === "warning" ? Theme.warning : Theme.fg
    }
}
