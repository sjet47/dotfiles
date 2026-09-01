//
// Matrix 雨屏保 —— 空闲 300s 铺满每块屏,任意输入即退。纯装饰,不做认证,不替代锁屏。
//
//   qs ipc call saver preview   立刻下雨(调样式用,不用真坐等 300s)
//   qs ipc call saver dismiss   收起
//
// 时间轴与 hypr/hypridle.conf 是**两份配置**,改一边记得改另一边:
//    300s  下雨            (这里)
//    880s  停画            (这里,见下)
//    900s  dpms off        (hypridle)
//   1800s  lock-session    (hypridle → hyprlock)
//
// 为什么 880 就停:hypridle 900s 直接把屏幕关了,继续往黑屏上渲染纯属白烧 GPU。
// 提前 20s 让 LazyLoader.active 转 false,整棵对象树连同那几千个 Text 一起回收 ——
// 屏保不显示时在进程里应当是零成本的,不能常驻(单实例本来就 ~370MB,见 ../README.md 坑 17)。
//
// 层级选 Overlay 是为了盖住 waybar:waybar 是 Top 层的 layer surface,kitty+cmatrix
// 那种普通 toplevel 窗口压根盖不住它。要反过来让 waybar 露在雨上面,把下面
// WlrLayershell.layer 改成 WlrLayer.Bottom 即可,其余不用动。
//
// 顺带一个 kitty+cmatrix 没有的好处:layer surface 不参与 dwindle 平铺,屏保每隔几分钟
// 弹一次也不会把布局搅乱(普通窗口会,见长期记忆 hyprland-dwindle-silent-focus)。
//
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: saver

    property int idleTimeout: 300
    property int stopTimeout: 880

    property bool forced: false      // IPC 手动拉起
    property bool dismissed: false   // 面板自己收到输入,不等 idle 事件绕回来

    // 全屏时不下雨。理论上看视频/玩游戏的应用**应该**申请 idle-inhibit
    // (IdleMonitor 的 respectInhibitors 会尊重它),但游戏和不少播放器根本不申请 ——
    // 用户实测全屏玩游戏照样弹,所以补这一道。
    //
    // 用 Wayland 协议层的 toplevel 状态,**不要用 Hyprland 的 workspace.hasfullscreen** ——
    // 那个字段在 Hyprland 0.56.2 上压根不反映全屏:实测把窗口切到全屏后
    // `activewindow.fullscreen` 已经是 2,`activeworkspace.hasfullscreen` 却还是 false。
    // ToplevelManager 走的是 wlr-foreign-toplevel-management,实测 false→true→false 准确。
    readonly property bool fullscreen: ToplevelManager.activeToplevel?.fullscreen ?? false

    // forced(IPC preview)刻意排在最前:调样式时不该被全屏或 idle 状态挡住
    readonly property bool running:
        saver.forced || (idleStart.isIdle && !idleStop.isIdle && !saver.dismissed
                         && !saver.fullscreen)

    function dismiss(): void {
        saver.forced = false;
        saver.dismissed = true;
    }

    IdleMonitor {
        id: idleStart
        timeout: saver.idleTimeout
        // 看视频 / 演示时应用会申请 idle-inhibit,跟着尊重就行,不用自己判断前台是谁
        respectInhibitors: true
        // 清 dismissed 必须挂在 isIdle 转 **true**(新一轮空闲开始)上,不能挂转 false。
        // 挂转 false 会有竞态:按键既让合成器发 resume、又走面板的 Keys 兜底,两者顺序不定,
        // resume 先到就会被随后的 dismiss() 重新置位 —— dismissed 从此卡死,屏保再不出现。
        onIsIdleChanged: if (this.isIdle) saver.dismissed = false
    }

    IdleMonitor {
        id: idleStop
        timeout: saver.stopTimeout
        respectInhibitors: true
    }

    IpcHandler {
        target: "saver"
        // 不能叫 show —— `qs ipc call <t> show` 会被当成 introspection 吃掉(../README.md 坑 15)
        function preview(): void { saver.dismissed = false; saver.forced = true }
        function dismiss(): void { saver.dismiss() }
        // 三个状态位(idle / forced / dismissed)肉眼看不出来,出问题时这是唯一的观测手段。
        // 典型用途:屏保没出现,是压根没触发,还是刚被一次输入收起了。
        function state(): string {
            return JSON.stringify({ running: saver.running, forced: saver.forced,
                dismissed: saver.dismissed, startIdle: idleStart.isIdle,
                stopIdle: idleStop.isIdle, fullscreen: saver.fullscreen,
                loaded: loader.item !== null });
        }
    }

    LazyLoader {
        id: loader
        active: saver.running

        Variants {
            // 每块屏都要盖住,所以这里不像通知那样只给活动屏建
            model: Quickshell.screens

            PanelWindow {
                id: win
                required property var modelData

                screen: win.modelData
                color: "black"
                exclusionMode: ExclusionMode.Ignore
                anchors { top: true; bottom: true; left: true; right: true }

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell:screensaver"
                // 吃掉唤醒的那次按键,否则它会穿透到底下的窗口里(在终端里凭空多一个字符)
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                // 面板刚出现时鼠标多半正停在它上面,hoverEnabled 的 enter 会立刻发一次
                // positionChanged —— 不设这道门,屏保会出现即消失。
                // 注意这道门只能用来**忽略事件**,不能拿它给 MouseArea 关 enabled:
                // hover enter 是在 MouseArea 变 enabled 的那一刻才补发的,拿 enabled 挡
                // 等于把那次假 position 精确地推迟到门开的瞬间,屏保照样自己收起。
                Timer { id: armed; interval: 600; running: true }

                // Keys 必须挂在 Item 上。直接写在 PanelWindow 里只会得到一句
                // "Could not attach Keys property to ... is not an Item" 的 WARN,
                // 面板照样独占键盘,但没人处理按键 —— 兜底静默失效。同 Power.qml 的写法。
                FocusScope {
                    anchors.fill: parent
                    focus: true

                    Keys.onPressed: event => {
                        event.accepted = true;
                        // 不做任何按键分支:Exclusive 独占键盘,收到就退,不给自己留锁死的机会
                        if (!armed.running) saver.dismiss();
                    }

                    MatrixRain { anchors.fill: parent }

                    MouseArea {
                        id: input
                        // 收到的第一个 position 事件是 hover enter 合成的,只拿来当基准点。
                        // 之后位移超过阈值才算"用户动了鼠标" —— 光靠 armed 计时不保险:
                        // enter 什么时候到取决于合成器,慢一点就会落到门开之后。
                        property real baseX: NaN
                        property real baseY: NaN

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.AllButtons

                        onPositionChanged: event => {
                            if (armed.running || isNaN(input.baseX)) {
                                input.baseX = event.x;
                                input.baseY = event.y;
                                return;
                            }
                            if (Math.hypot(event.x - input.baseX, event.y - input.baseY) > 4)
                                saver.dismiss();
                        }
                        onPressed: if (!armed.running) saver.dismiss()
                        onWheel: if (!armed.running) saver.dismiss()
                    }
                }
            }
        }
    }
}
