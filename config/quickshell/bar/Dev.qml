//
// 调试用入口:`qs -p config/quickshell/bar/Dev.qml`
//
// 起一个**独立实例**只跑状态栏,不碰主实例(主实例带着通知守护,一个语法错误就能把
// 通知/OSD/屏保一起卸掉 —— 迁移期间尤其别拿主实例试错)。
//
// atBottom 把栏放到屏幕底部,这样可以和顶上的真 waybar 并排比对着调。
//
import Quickshell

ShellRoot {
    Bar { atBottom: true }
}
