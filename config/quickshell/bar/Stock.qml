//
// 股价(= waybar 的 custom/stock),数据源仍是迁移前那个脚本 scripts/stock.sh。
//
// 脚本原样保留:它自己管缓存和盘前/盘后标记,没有理由用 QML 重写一遍。waybar 那边是
// `interval: 3` 每 3 秒重跑一次,这里就是一个 3 秒的 Timer 重新 running 一次。
//
// **脚本输出的是 Pango 标记**(waybar 用 GTK 渲染),Qt 的 StyledText 不认 `<span foreground=>`,
// 得换成 `<font color=>` —— 不换的话标签会被整个吞掉,涨跌色全丢(表现为纯白文字)。
//
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

BarItem {
    id: root

    // 相对本文件解析,这样主实例(shellRoot=config/quickshell)和 dev 实例
    // (shellRoot=config/quickshell/bar)两种跑法都能找到脚本
    readonly property string script: Qt.resolvedUrl("scripts/stock.sh").toString().replace("file://", "")

    property string label: ""
    property string tip: ""

    // 可用宽度上限(由 Bar.qml 按左右两组之间的空隙算出)。<=0 表示不限制。
    // 超了就右侧截断 —— 窄屏上宁可看半截股价,也不能压到别的模块上。
    property real maxWidth: -1

    marginLeft: 0
    marginRight: 0
    padding: 6                                       // #custom-stock { padding: 0 6px }
    tooltipText: root.tip

    Process {
        id: proc
        command: [root.script, "VOO", "QQQ"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(this.text.trim());
                    root.label = (j.text ?? "")
                        .replace(/<span foreground="/g, '<font color="')
                        .replace(/<\/span>/g, "</font>");
                    root.tip = j.tooltip ?? "";
                } catch (e) {
                    // 脚本偶发失败(网络抖动)时保留上一次的数字,不要闪成空白
                }
            }
        }
    }

    Timer {
        interval: 3000                               // = config.jsonc 的 "interval": 3
        running: true
        repeat: true
        onTriggered: proc.running = true
    }

    Text {
        // implicitWidth 始终是未截断的自然宽度,所以拿它和上限比不会形成绑定环
        width: root.maxWidth > 0
               ? Math.min(implicitWidth, Math.max(0, root.maxWidth - 2 * root.padding))
               : implicitWidth
        elide: Text.ElideRight
        text: root.label
        textFormat: Text.StyledText
        font.family: Theme.font
        renderType: Text.NativeRendering
        font.hintingPreference: Theme.hinting
        font.pixelSize: Theme.fontSize
        font.features: ({ "tnum": 1 })               // font-feature-settings: "tnum"
        color: Theme.fg
    }
}
