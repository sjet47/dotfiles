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
//   osd/Track.qml          曲目切换 OSD            IPC target: track
//
// 另有常驻但平时不占资源的:
//   screensaver/           空闲 300s 的 matrix 雨屏保      IPC target: saver
//
// bar/ 里有一条完整的状态栏(替代 waybar),但**当前没有接进来** —— 2026-08-27 迁移做完后
// 用户决定先继续用 waybar,状态栏留着自己有空再微调。要重新启用,把下面被注释掉的目录导入
// 和 ShellRoot 里对应的那行实例化一起放开。单独调它不用动这里:
//   qs -p config/quickshell/bar/Dev.qml
//
// **这段注释里一个花括号都不能出现** —— 见 README 坑 38:imports 之前的注释里只要出现
// 左花括号,quickshell 就认为根对象已经开始,后面的目录导入全部收集不到,表现是 osd/ 里
// 每个类型都报 "X is not a type"。
//
// 子目录不会被 quickshell 当成独立配置(default 配置存在时它不扫子目录),
// 这里是靠 QML 的目录导入把里面的组件拿进来。
//
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
// import "bar"          // 状态栏当前未启用,见文件头
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
    Notifications { id: notifications; activeMonitor: root.activeMonitor }
    Power { activeMonitor: root.activeMonitor }
    Track { activeMonitor: root.activeMonitor }

    // 状态栏当前未启用(用户 2026-08-27 决定先继续用 waybar)。放开这行即可接回来:
    //   Bar { notifications: notifications }
    // 接回来之后免打扰状态和历史是属性绑定,waybar 那条
    // "脚本 → qs ipc → pkill -RTMIN+1 waybar" 的回路就可以再删一次。

    // 不吃 activeMonitor:屏保要盖住每一块屏,不是只跟着焦点走。
    //
    // 这里的声明顺序不决定它和通知谁在上。同为 overlay 层时合成器按 surface 创建先后叠,
    // 而通知的 surface 是收到通知那一刻才建的,永远比常驻的屏保晚 —— 所以**通知会浮在雨上面**
    // (已实测:雨铺满时 notify-send 一条,卡片正常压在雨上)。这正是想要的:屏保期间来消息
    // 仍看得见。真要让雨盖住通知,得去调 Notifications 的层级,挪这行没用。
    Screensaver {}
}
