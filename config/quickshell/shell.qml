//
// 桌面 shell 入口 —— 整个桌面只跑这一个 quickshell 实例(`qs`,不需要 -c)。
//
// 放在 ~/.config/quickshell/shell.qml 就是 quickshell 的 "default" 配置;
// 注意此时同目录下的子目录不会再被当成独立配置。
//
// 组成(都在 osd/ 子目录下,都是转瞬即逝的屏上覆盖层):
//   osd/Osd.qml            音量 / 亮度 / 麦克风    IPC target: osd
//   osd/Notifications.qml  通知守护(替代 mako)     IPC target: notif
//   osd/Power.qml          电源菜单(替代 wlogout)  IPC target: power
//
// 另有常驻但平时不占资源的:
//   screensaver/           空闲 300s 的 matrix 雨屏保      IPC target: saver
//
// 子目录不会被 quickshell 当成独立配置(default 配置存在时它不扫子目录),
// 这里是靠 QML 的目录导入把里面的组件拿进来。
//
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "osd"
import "screensaver"

ShellRoot {
    id: root

    // Hyprland.focusedMonitor 只在收到 focusedmon 事件时才赋值,shell 刚起来时是 null
    // (实测启动 3s 后仍为 undefined)。所以启动时用 hyprctl 播种一次,之后交给事件流。
    // 两个组件共用,不各自再查一遍。
    property string seedMonitor: ""
    readonly property string activeMonitor: Hyprland.focusedMonitor?.name ?? root.seedMonitor

    Process {
        running: true
        command: ["sh", "-c", "hyprctl monitors -j | jq -r '.[]|select(.focused)|.name'"]
        stdout: StdioCollector { onStreamFinished: root.seedMonitor = this.text.trim() }
    }

    Osd { activeMonitor: root.activeMonitor }
    Notifications { activeMonitor: root.activeMonitor }
    Power { activeMonitor: root.activeMonitor }

    // 不吃 activeMonitor:屏保要盖住每一块屏,不是只跟着焦点走。
    //
    // 这里的声明顺序不决定它和通知谁在上。同为 overlay 层时合成器按 surface 创建先后叠,
    // 而通知的 surface 是收到通知那一刻才建的,永远比常驻的屏保晚 —— 所以**通知会浮在雨上面**
    // (已实测:雨铺满时 notify-send 一条,卡片正常压在雨上)。这正是想要的:屏保期间来消息
    // 仍看得见。真要让雨盖住通知,得去调 Notifications 的层级,挪这行没用。
    Screensaver {}
}
