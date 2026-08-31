//
// 状态栏 —— 替代 waybar。
//
// 布局与配色 1:1 复刻迁移前的 config/waybar/{config.jsonc,style.css};逐条对应关系写在
// 各模块头上,数值统一收在 Theme.qml。只有两处是**刻意新增**的交互(用户 2026-08-27 决定):
//   - 托盘可折叠,展开是个悬浮面板(waybar 做这个很别扭,是这次迁移的直接动机)
//   - CPU / 内存的悬浮详情面板(逐核占用),waybar 只能塞进 tooltip 字符串里
//
// 数据来源分三类:
//   1. quickshell 原生服务:workspaces / tray / 音量 / 电池 / 键盘电量 / 蓝牙 / 网络 / 时钟
//   2. 自己读 /proc:CPU / 内存 / 网络吞吐,见 SysInfo.qml
//   3. 沿用 waybar 时代的脚本当数据源:股价、Claude 用量(见 Stock.qml / ClaudeUsage.qml)
//
// **Hyprland 相关的坑**:不要手动调 `Hyprland.refreshMonitors()` / `refreshWorkspaces()`,
// 见 README 坑 27 —— 并发请求会互相冲掉,表现是 monitors 恒为 0、workspace id 恒为 -1。
// 只读属性即可,quickshell 自己那一轮启动刷新 + 事件流会把它们填好。
//
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire

Scope {
    id: bar

    // 通知守护(osd/Notifications.qml)的实例,由 shell.qml 传进来。
    // 迁移前这块是 waybar → notifications.sh → `qs ipc call notif` → `pkill -RTMIN+1 waybar`
    // 一整圈;现在就是两个属性绑定。dev 实例(Dev.qml)里没有守护,所以要容忍 null。
    property var notifications: null

    // dev 实例把状态栏放到屏幕底部,免得和真 waybar 抢同一块地方。
    property bool atBottom: false

    // 音量要 track 才会更新(同 Osd.qml)
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    // 一条竖分隔线 + 两侧留白。= style.css 里 #tray/#cpu/#clock 的
    // `margin-left:14px; padding-left:14px; border-left:1px solid @separator`
    component Sep: Item {
        width: Theme.groupGap * 2 + 1
        height: Theme.barHeight
        Rectangle {
            x: Theme.groupGap
            width: 1
            height: parent.height
            color: Theme.separator
        }
    }

    // **每块屏都要有一条状态栏,这里不许加 filter。**
    // osd/Notifications.qml 用的是 `Quickshell.screens.filter(s => s.name === activeMonitor)`
    // (README 坑 7:只给活动屏建面板,省掉隐藏屏上整列 delegate 的实例化和图片解码),
    // 照抄到状态栏上就变成"只有焦点屏有 bar",切屏时另一块屏的栏会凭空消失。
    // 状态栏是常驻的、每块屏都得在,而且它没有那种按屏重建的开销 —— 保持 model 不过滤。
    //
    // 相应地,一切"当前"语义都必须按**本面板这块屏**算,不能用全局焦点:
    // 工作区圆点走 panel.modelData.name(见 Workspaces.qml 头注释)。
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData

            readonly property var hyprMonitor: Hyprland.monitorFor(panel.modelData)

            screen: modelData
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Top
            // 模糊是 Hyprland 的 layer_rule 按 namespace 匹配的。迁移时 looknfeel.lua 里
            // 那条 `match = { namespace = "waybar" }` 必须跟着改成这个名字,否则背景色
            // rgba(28,28,30,.78) 后面没有模糊,直接透出桌面。
            WlrLayershell.namespace: "quickshell-bar"

            anchors.top: !bar.atBottom
            anchors.bottom: bar.atBottom
            anchors.left: true
            anchors.right: true
            margins.top: Theme.marginTop
            margins.bottom: Theme.marginTop
            margins.left: Theme.marginSide
            margins.right: Theme.marginSide
            implicitHeight: Theme.barHeight

            // 背景和边框**必须分成两层画**。
            //
            // Qt 的 `Rectangle.border` 画在填充之外 —— 那一圈 1px 里没有背景色,
            // `#12ffffff`(白 7%)是直接压在壁纸上的,于是上下各出现一条亮线
            // (实测亮度 86,而栏体是 38;壁纸 72 × 0.93 + 255 × 0.07 = 85,正好对上)。
            // GTK 的 border 压在背景上,所以 waybar 那条几乎看不见(实测 45~53)。
            //
            // 症状不是"多了条线"这么直观:深色栏体被这两条亮线从 46px 削成 43px,
            // 看起来**整条栏变矮了**,里面的文字也跟着变成上 13 下 5、像没居中。
            // 用户就是这么描述的。
            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.bg

                // 边框单独一层,叠在背景上 —— 这样它 composite 的对象是栏体而不是壁纸
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    color: "transparent"
                    border.color: Theme.border
                    border.width: 1
                }

                // ---------------- 左 ----------------
                Row {
                    id: left
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.edgePad          // .modules-left { margin-left: 10px }
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    BarItem {                                   // #custom-arch
                        marginLeft: 4
                        marginRight: 10                         // margin: 0 10px 0 4px
                        padding: 0                              // 不在 style.css 那条 `padding: 0 2px` 的选择器列表里
                        tooltipText: "Arch Linux"
                        Text {
                            text: "\uf303"                     // nf-linux-archlinux,= config.jsonc 的 format
                            font.family: Theme.iconFont
                            renderType: Text.NativeRendering
                            font.hintingPreference: Theme.hinting
                            font.pixelSize: 18                  // #custom-arch { font-size: 18px }
                            color: Theme.fg
                        }
                    }

                    Item {                                      // #workspaces { margin: 0 4px }
                        width: ws.implicitWidth + 8
                        height: Theme.barHeight
                        Workspaces {
                            id: ws
                            x: 4
                            anchors.verticalCenter: parent.verticalCenter
                            monitorName: panel.modelData.name
                        }
                    }

                    Sep {}                                      // #workspaces 的 border-right
                }

                // ---------------- 中 ----------------
                // **不能用 anchors.centerIn** —— 窄屏(竖着的那块 1440 逻辑宽)上左右两组
                // 占掉的宽度超过一半时,硬居中会直接压到右组上,文字叠文字(实测在 HDMI-A-1 上
                // 股价和 cpu/内存糊成一团)。
                //
                // waybar 那边是 GTK CenterBox:放得下就居中,放不下就退化成顺序排布(实测它
                // 甚至会把 arch 图标挤掉)。这里复刻前半段 —— 居中位置去夹在左右两组之间,
                // 真的挤不下就把自己截断,绝不重叠。
                Stock {
                    id: center

                    readonly property real leftEnd: left.x + left.width
                    readonly property real rightStart: right.x
                    readonly property real gap: Math.max(0, center.rightStart - center.leftEnd)

                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(center.leftEnd,
                                Math.min((parent.width - center.width) / 2, center.rightStart - center.width))
                    maxWidth: center.gap
                    visible: center.gap > 60          // 连截断都没意义了就整个不显示
                }

                // ---------------- 右 ----------------
                Row {
                    id: right
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.edgePad         // .modules-right { margin-right: 10px }
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0

                    Sep {}                                     // #tray 的 border-left
                    Tray { anchors.verticalCenter: parent.verticalCenter }
                    Sep {}                                     // #cpu 的 border-left

                    SysMon {}                                  // cpu + memory,含悬浮详情

                    BarItem {                                  // #custom-netio
                        tooltipText: "↑ " + SysInfo.fmtRate(SysInfo.netTx) + "/s   ↓ "
                                     + SysInfo.fmtRate(SysInfo.netRx) + "/s"
                        Text {
                            text: "󰓡 ↑" + SysInfo.fmtRate(SysInfo.netTx)
                                  + " ↓" + SysInfo.fmtRate(SysInfo.netRx)
                            font.family: Theme.font
                            renderType: Text.NativeRendering
                            font.hintingPreference: Theme.hinting
                            font.pixelSize: Theme.fontSize
                            color: Theme.fg
                        }
                    }

                    ClaudeUsage {}                             // #custom-claude

                    BarItem {                                  // #custom-keyboard(键盘电量)
                        id: kb
                        // 迁移前是 kb-battery.sh 起一个常驻进程盯 `upower --monitor`;
                        // UPower 服务本来就在推这些变化,脚本可以整个删掉。
                        readonly property var dev: {
                            for (const d of UPower.devices.values)
                                if (d.type === UPowerDeviceType.Keyboard) return d;
                            return null;
                        }
                        readonly property int pct: Math.round((kb.dev?.percentage ?? 0) * 100)

                        visible: kb.dev !== null
                        width: visible ? implicitWidth : 0
                        tooltipText: (kb.dev?.model ?? "Keyboard") + ": " + kb.pct + "%"
                        onClicked: Quickshell.execDetached(["blueman-manager"])

                        Text {
                            // 10 级电池图标,与 waybar battery 模块同一组字形
                            readonly property var icons: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
                            text: icons[Math.min(9, Math.floor(kb.pct / 10))] + " " + kb.pct + "%"
                            font.family: Theme.font
                            renderType: Text.NativeRendering
                            font.hintingPreference: Theme.hinting
                            font.pixelSize: Theme.fontSize
                            color: kb.pct <= 10 ? Theme.critical : (kb.pct <= 20 ? Theme.warning : Theme.fg)
                        }
                    }

                    BarItem {                                  // #bluetooth
                        id: bt
                        readonly property var adapter: Bluetooth.defaultAdapter
                        readonly property int connected:
                            (Bluetooth.devices?.values ?? []).filter(d => d.connected).length

                        tooltipText: "Devices connected: " + bt.connected
                        onClicked: Quickshell.execDetached(["blueman-manager"])

                        Text {
                            text: !bt.adapter ? ""                                 // format-no-controller
                                  : !bt.adapter.enabled ? "\udb80\udcb2"            // 󰂲 format-off/disabled
                                  : bt.connected > 0 ? "\udb80\udcb1"               // 󰂱 format-connected
                                  : "\uf294"                                        // format(nf-fa-bluetooth)
                            font.family: Theme.iconFont
                            renderType: Text.NativeRendering
                            font.hintingPreference: Theme.hinting
                            font.pixelSize: Theme.fontSize
                            color: Theme.fg
                        }
                    }

                    BarItem {                                  // #network
                        id: net
                        readonly property var wired: {
                            for (const d of (Networking.devices?.values ?? []))
                                if (d.type === DeviceType.Wired && d.state === ConnectionState.Connected) return d;
                            return null;
                        }
                        readonly property var wifi: {
                            for (const d of (Networking.devices?.values ?? []))
                                if (d.type === DeviceType.Wifi && d.state === ConnectionState.Connected) return d;
                            return null;
                        }
                        readonly property bool offline: !net.wired && !net.wifi

                        tooltipText: net.wired ? "Connected"
                                     : net.wifi ? (net.wifi.network?.name ?? "Wi-Fi")
                                     : "Disconnected"
                        onClicked: Quickshell.execDetached(["nm-connection-editor"])

                        Text {
                            // format-icons 是 5 档信号,format-ethernet 是 󰀂
                            readonly property var wifiIcons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
                            text: net.wired ? "󰀂"
                                  : net.wifi ? wifiIcons[Math.min(4, Math.floor((net.wifi.network?.signalStrength ?? 0) / 20))]
                                  : "󰤮"
                            font.family: Theme.iconFont
                            renderType: Text.NativeRendering
                            font.hintingPreference: Theme.hinting
                            font.pixelSize: Theme.fontSize
                            color: net.offline ? Theme.muted : Theme.fg   // #network.disconnected
                        }
                    }

                    BarItem {                                  // #pulseaudio
                        id: vol
                        readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
                        readonly property int pct: Math.round((vol.audio?.volume ?? 0) * 100)
                        readonly property bool muted: vol.audio?.muted === true

                        tooltipText: (Pipewire.defaultAudioSink?.description ?? "") + " — " + vol.pct + "%"
                        onClicked: b => {
                            if (b === Qt.LeftButton) Quickshell.execDetached(["pavucontrol"]);
                            else if (b === Qt.RightButton && vol.audio) vol.audio.muted = !vol.audio.muted;
                        }
                        // scroll-step: 5
                        onScrolled: d => { if (vol.audio) vol.audio.volume = Math.max(0, Math.min(1, vol.audio.volume + (d > 0 ? 0.05 : -0.05))); }

                        Text {
                            text: (vol.muted ? "󰝟" : vol.pct < 34 ? "󰕿" : vol.pct < 67 ? "󰖀" : "󰕾")
                                  + " " + vol.pct + "%"
                            font.family: Theme.font
                            renderType: Text.NativeRendering
                            font.hintingPreference: Theme.hinting
                            font.pixelSize: Theme.fontSize
                            color: vol.muted ? Theme.muted : Theme.fg     // #pulseaudio.muted
                        }
                    }

                    BarItem {                                  // #battery(台式机上没有,自动隐藏)
                        id: batt
                        readonly property var dev: UPower.displayDevice
                        readonly property bool present: batt.dev?.isLaptopBattery === true
                        readonly property int pct: Math.round((batt.dev?.percentage ?? 0) * 100)
                        readonly property bool charging: batt.dev?.state === UPowerDeviceState.Charging

                        visible: batt.present
                        width: visible ? implicitWidth : 0
                        tooltipText: (batt.charging ? "↑ " : "↓ ") + batt.pct + "%"

                        Text {
                            readonly property var full: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
                            readonly property var chg:  ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
                            text: (batt.charging ? chg : full)[Math.min(9, Math.floor(batt.pct / 10))]
                            font.family: Theme.iconFont
                            renderType: Text.NativeRendering
                            font.hintingPreference: Theme.hinting
                            font.pixelSize: Theme.fontSize
                            color: batt.pct <= 10 ? Theme.critical : (batt.pct <= 20 ? Theme.warning : Theme.fg)
                        }
                    }

                    Sep {}                                     // #clock 的 border-left

                    BarItem {                                  // #clock
                        id: clock
                        // format-alt:点一下在完整日期和"周几 + 周数 + 时分"之间切
                        property bool alt: false
                        marginLeft: 0
                        marginRight: 0
                        padding: 0                              // 同上,#clock 也不在通用 padding 列表里
                        onClicked: clock.alt = !clock.alt

                        Text {
                            text: clock.alt
                                  ? Qt.formatDateTime(clockSource.date, "dddd 'W'ww HH:mm")
                                  : Qt.formatDateTime(clockSource.date, "yyyy-MM-dd HH:mm:ss dddd")
                            font.family: Theme.font
                            renderType: Text.NativeRendering
                            font.hintingPreference: Theme.hinting
                            font.pixelSize: Theme.fontSize
                            // font-feature-settings: "tnum" —— 等宽数字,秒跳动时整块不抖
                            font.features: ({ "tnum": 1 })
                            color: Theme.fg
                        }
                    }

                    BarItem {                                  // #custom-notifications
                        id: notif
                        readonly property bool dnd: bar.notifications?.dnd === true

                        marginLeft: 10
                        marginRight: 0
                        padding: 4                              // padding: 0 4px
                        tooltipText: "左键查看历史 / 右键切换免打扰"
                        onClicked: b => {
                            if (!bar.notifications) return;
                            if (b === Qt.RightButton) bar.notifications.dnd = !bar.notifications.dnd;
                            else notif.showHistory();
                        }

                        // 历史沿用迁移前的做法:丢给 vicinae dmenu。
                        // (进程内直连之后完全可以画成真正的历史面板,但这轮的范围是 1:1 复刻。)
                        function showHistory(): void {
                            const log = bar.notifications?.log ?? [];
                            const list = log.length === 0 ? "（无历史消息）"
                                : log.map(n => "[" + (n.appName || "?") + "] " + (n.summary || "")
                                               + " — " + (n.body || "").replace(/\n/g, " ")).join("\n");
                            Quickshell.execDetached(["sh", "-c",
                                'printf "%s" "$1" | vicinae dmenu --section-title="通知历史({count})" --width=720 --no-footer >/dev/null',
                                "sh", list]);
                        }

                        Text {
                            text: notif.dnd ? "󰂛" : "󰂚"
                            font.family: Theme.iconFont
                            renderType: Text.NativeRendering
                            font.hintingPreference: Theme.hinting
                            font.pixelSize: Theme.fontSize
                            color: Theme.fg
                        }
                    }
                }
            }
        }
    }

    SystemClock {
        id: clockSource
        precision: SystemClock.Seconds
    }
}
