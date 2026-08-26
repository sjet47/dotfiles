//
// 桌面 shell 入口 —— 整个桌面只跑这一个 quickshell 实例(`qs`,不需要 -c)。
//
// 放在 ~/.config/quickshell/shell.qml 就是 quickshell 的 "default" 配置;
// 注意此时同目录下的子目录不会再被当成独立配置。
//
// 组成:
//   Osd.qml            音量 / 亮度 OSD      IPC target: osd
//   Notifications.qml  通知守护(替代 mako)  IPC target: notif
//   Power.qml          电源菜单(替代 wlogout) IPC target: power
//
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

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
}
