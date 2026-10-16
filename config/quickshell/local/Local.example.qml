// 本机配置模板
// ============================================================
// 复制本文件为 local/Local.qml 并按本机情况修改。
// local/ 目录除本文件外都被 gitignore,Local.qml 不入库。
// 入口 shell.qml 用 Loader 按路径加载 Local.qml(不是 import "local":import 缺文件会让
// 整个 shell 加载失败,Loader 只报一条 warning),缺失时各项取下面的默认值。
// 改 Local.qml 也会触发热重载(shell.qml 里有 FileView 盯着它);新建本文件后碰一下任意 QML 即可。
import QtQuick

QtObject {
    // 通知固定显示的屏幕,写 hyprctl monitors 里的 name。
    // 空串 = 跟焦点屏走;指定的屏不在(拔了、改名)时也回退到焦点屏。
    property string notifMonitor: ""
}
