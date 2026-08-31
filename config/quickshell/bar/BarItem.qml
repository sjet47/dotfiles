//
// 状态栏模块的通用外壳:内容容器 + 鼠标事件 + 悬浮浮层。
//
// **这个文件就是这次迁移的理由**。waybar 里"给某个模块挂个悬浮窗"要么只能塞进
// tooltip-format 那根字符串里,要么另起一个进程画窗口;这里 `tooltipItem` 收一个
// Component,想画什么画什么(进度条、逐核柱状图、按钮都行),浮层的定位/跟随/收起
// 由 PopupWindow 自己管。
//
// 用法:
//   BarItem {
//       tooltipText: "简单文本浮层"          // 二选一
//       tooltipItem: Component { ... }        // 想画复杂的就用这个,优先级高于 tooltipText
//       onClicked: b => { if (b === Qt.LeftButton) ... }
//       Text { ... }                          // 默认属性,直接往里塞内容
//   }
//
// margin 的语义照搬 CSS:在内容盒之外,**不参与点击**(GTK 里 margin 也不响应事件),
// 所以 MouseArea 和浮层锚点都挂在 holder 上而不是整个 Item 上。
//
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Item {
    id: root

    // 内容直接放进一个 Row:既拿到隐式尺寸(不用碰 childrenRect),
    // 又让"图标 + 文本"这种最常见的组合不必每个模块自己再包一层。
    default property alias content: holder.data

    property int marginLeft: Theme.itemMargin      // = style.css 通用规则 margin: 0 8px
    property int marginRight: Theme.itemMargin
    property int padding: Theme.itemPad            // = padding: 0 2px

    property string tooltipText: ""
    property Component tooltipItem: null
    property int spacing: 6

    // 悬浮多久才弹。waybar/GTK 的默认约 500ms,这里略快一点。
    property int tooltipDelay: 350

    readonly property bool hovered: mouse.containsMouse

    signal clicked(int button)
    signal scrolled(int delta)

    implicitWidth: holder.implicitWidth + 2 * root.padding + root.marginLeft + root.marginRight
    implicitHeight: Theme.barHeight

    Item {
        id: box                                     // 内容盒(含 padding),margin 在它外面
        x: root.marginLeft
        width: holder.implicitWidth + 2 * root.padding
        height: parent.height

        Row {
            id: holder
            x: root.padding
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.spacing
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: e => root.clicked(e.button)
            onWheel: e => root.scrolled(e.angleDelta.y)
        }
    }

    Timer {
        id: delay
        interval: root.tooltipDelay
        onTriggered: popup.active = true
    }

    // 指针一离开就立刻收,不留延迟 —— 浮层是"看一眼就走"的东西,拖尾会挡住下面的窗口。
    onHoveredChanged: {
        if (root.hovered && (root.tooltipText !== "" || root.tooltipItem !== null))
            delay.restart();
        else {
            delay.stop();
            popup.active = false;
        }
    }

    // 用 Loader 而不是常驻 PopupWindow:十几个模块每个都常驻一个 wayland surface 太浪费,
    // 而且没弹出来的浮层里那些绑定(逐核占用之类)也会一直在算。
    Loader {
        id: popup
        active: false

        sourceComponent: PopupWindow {
            anchor.item: box
            anchor.edges: Edges.Bottom
            anchor.gravity: Edges.Bottom
            anchor.margins.top: 6
            // 状态栏在顶部时浮层往下开;但 Dev.qml 把栏放到屏幕底部调试,那时"往下"
            // 会整块跑到屏幕外(**看起来就像浮层根本没弹**)。FlipY 让合成器自己翻到上方,
            // 顺带也保住了以后把栏挪到底部的可能。SlideX 管的是贴近屏幕左右边缘的模块。
            anchor.adjustment: PopupAdjustment.FlipY | PopupAdjustment.SlideX
            visible: true
            color: "transparent"
            implicitWidth: frame.implicitWidth
            implicitHeight: frame.implicitHeight

            Rectangle {
                id: frame
                anchors.fill: parent
                implicitWidth: (root.tooltipItem ? inner.implicitWidth : label.implicitWidth) + 16
                implicitHeight: (root.tooltipItem ? inner.implicitHeight : label.implicitHeight) + 8
                radius: 8
                color: Theme.tooltipBg
                border.color: Theme.tooltipBorder
                border.width: 1

                Text {
                    id: label
                    visible: !root.tooltipItem
                    anchors.centerIn: parent
                    text: root.tooltipText
                    textFormat: Text.StyledText
                    color: Theme.fg
                    font.family: Theme.font
                    renderType: Text.NativeRendering
                    font.hintingPreference: Theme.hinting
                    font.pixelSize: 14
                }

                Loader {
                    id: inner
                    anchors.centerIn: parent
                    sourceComponent: root.tooltipItem
                }
            }
        }
    }
}
