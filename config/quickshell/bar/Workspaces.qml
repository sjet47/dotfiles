//
// 工作区指示器(= waybar 的 hyprland/workspaces)。
//
// 复刻 config.jsonc 里的三条语义:
//   - persistent-workspaces 1..5 恒显,哪块屏上都显示(原配置每项的值是空数组 = all outputs)
//   - format-icons:活动工作区显示圆点 󱓻,其余显示自己的数字
//   - .empty(没有窗口)半透明,靠 style.css 的 opacity: 0.5
//
// **非活动工作区的数字是前景色,不是 @muted** —— 别照着 CSS 直译。style.css 里写的是
// `#workspaces button { color: @muted }`,但 waybar 的按钮里还有个 label 子控件,顶部的
// `* { color: @foreground }` 直接命中那个 label,而 `#workspaces button` 命中的是按钮本身,
// 两条规则作用在不同控件上,所以 label 的前景色赢了。结果是 @muted 那行**从来没生效过**
// (`button:hover { color: @foreground }` 同理是空转)。实测取色:非活动数字 = (245,245,247)
// = #f5f5f7,空工作区 = 前景色压 0.5 而不是 muted 压 0.5。
//
// **"活动"必须是"在本屏上活动"**:HyprlandWorkspace.active 的语义是"在它自己那块屏上活动",
// 所以双屏时 DP-1 和 HDMI-A-1 的当前工作区**同时**为 true。直接拿它点圆点,两块屏的状态栏
// 会各点亮两个。要再比一次 monitor 名(实测:迁移前 waybar 在 DP-1 上就只有 1 是圆点,
// 2 是普通亮数字)。
//
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property string monitorName

    implicitWidth: row.implicitWidth + 4      // button 的 margin: 4px 2px,左右各 2
    implicitHeight: Theme.barHeight

    // 1..5 恒显 + 已存在的其余普通工作区(special:* 不进状态栏),按 id 排序。
    readonly property var items: {
        const byId = {};
        for (let i = 1; i <= 5; i++) byId[i] = null;
        for (const w of Hyprland.workspaces.values) {
            if (w.id < 1) continue;                 // special:scratchpad 是负数 id
            byId[w.id] = w;
        }
        return Object.keys(byId).map(k => parseInt(k)).sort((a, b) => a - b)
                     .map(id => ({ id: id, ws: byId[id] }));
    }

    Row {
        id: row
        x: 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4                            // 相邻 button 的 margin 2 + 2

        Repeater {
            model: root.items

            Rectangle {
                id: btn
                required property var modelData

                readonly property var ws: modelData.ws
                // "在本屏上活动" —— 见文件头注释,少了后半句双屏会同时点亮两个
                readonly property bool isActive: btn.ws?.active === true
                                                 && btn.ws?.monitor?.name === root.monitorName
                readonly property bool isEmpty: !btn.ws || (btn.ws.lastIpcObject?.windows ?? 0) === 0

                // style.css: padding 0 9px; margin 4px 2px; min-width 10px; border-radius 7px
                width: Math.max(10, label.implicitWidth) + 18
                height: Theme.barHeight - 8
                anchors.verticalCenter: parent.verticalCenter
                radius: 7
                color: btn.isActive ? Theme.bgActive : (hover.containsMouse ? Theme.bgHover : "transparent")
                opacity: btn.isEmpty && !btn.isActive ? 0.5 : 1

                Behavior on color   { ColorAnimation  { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Text {
                    id: label
                    anchors.centerIn: parent
                    // 活动是圆点,其余是数字;10 号显示 0,跟 format-icons 一致
                    text: btn.isActive ? "󱓻" : (btn.modelData.id === 10 ? "0" : String(btn.modelData.id))
                    font.family: btn.isActive ? Theme.iconFont : Theme.font
                    renderType: Text.NativeRendering
                    font.hintingPreference: Theme.hinting
                    font.pixelSize: Theme.fontSize
                    color: Theme.fg          // 见文件头:muted 在 waybar 里其实没生效过
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Hyprland.dispatch("workspace " + btn.modelData.id)
                }
            }
        }
    }
}
