//
// 系统托盘(= waybar 的 tray),**可折叠**。
//
// 折叠是这次迁移的两处刻意新增之一(用户 2026-08-27 决定)。默认收起成一个 V 形按钮,
// 点开是一块悬浮面板 —— waybar 侧要做到这个得自己另起窗口,这里就是一个 PopupWindow。
// 想改回"永远铺开",把 collapsed 的初值改成 false 即可(展开态就是原来的一排图标)。
//
// 图标尺寸/间距沿用 config.jsonc 的 tray:{ icon-size: 18, spacing: 12 }。
//
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root

    property bool collapsed: true

    // 面板里悬停到哪一项(展开面板底部显示它的名字 —— 不给每个图标再套一层
    // PopupWindow:浮层套浮层在 Wayland 上定位和层级都不好收拾,一个窗口够用)
    property string hoveredName: ""

    readonly property var items: SystemTray.items?.values ?? []
    // NeedsAttention(2) 的条目在收起时也要能看见,否则"有事找你"的提示会被折没
    readonly property int attention: root.items.filter(i => i.status === 2).length

    implicitWidth: toggle.implicitWidth
    implicitHeight: Theme.barHeight
    width: implicitWidth

    BarItem {
        id: toggle
        marginLeft: 0
        marginRight: 0
        tooltipText: root.items.length === 0 ? "托盘为空"
                     : root.collapsed ? ("托盘 " + root.items.length + " 项 — 点击展开")
                     : "点击收起"
        onClicked: root.collapsed = !root.collapsed

        Text {
            // nf-fa-chevron_left 收起 / nf-fa-chevron_down 展开
            text: root.collapsed ? "\uf053" : "\uf078"
            font.family: Theme.iconFont
            renderType: Text.NativeRendering
            font.hintingPreference: Theme.hinting
            font.pixelSize: Theme.fontSize
            color: root.attention > 0 && root.collapsed ? Theme.warning : Theme.fg
        }
    }

    // 展开面板。挂在 toggle 上,跟着状态栏走。
    LazyLoader {
        id: panel
        active: !root.collapsed && root.items.length > 0

        PopupWindow {
            id: win
            anchor.item: toggle
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
                implicitWidth: Math.max(row.implicitWidth, name.implicitWidth) + 20
                implicitHeight: 34 + (name.text === "" ? 0 : name.implicitHeight + 6)
                radius: 10
                color: Theme.tooltipBg
                border.color: Theme.tooltipBorder
                border.width: 1

                Behavior on implicitHeight { NumberAnimation { duration: 100 } }

                Row {
                    id: row
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4
                    spacing: 12                                  // tray.spacing

                    Repeater {
                        model: root.items

                        Item {
                            id: cell
                            required property var modelData

                            width: 26
                            height: 26

                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: cellHover.containsMouse ? Theme.bgHover : "transparent"
                            }

                            Image {
                                anchors.centerIn: parent
                                width: 18                        // tray.icon-size
                                height: 18
                                source: cell.modelData.icon
                                sourceSize.width: 36             // 按 2x 解码,高分屏下不糊也不浪费
                                sourceSize.height: 36
                                smooth: true
                            }

                            MouseArea {
                                id: cellHover
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: e => {
                                    if (e.button === Qt.LeftButton && !cell.modelData.onlyMenu)
                                        cell.modelData.activate();
                                    else if (cell.modelData.hasMenu)
                                        // display() 的坐标是相对**这个窗口**的,所以传 win 而不是状态栏
                                        cell.modelData.display(win, row.x + cell.x + cell.width / 2, frame.height);
                                }
                                onContainsMouseChanged: root.hoveredName = containsMouse
                                    ? (cell.modelData.tooltipTitle || cell.modelData.title || cell.modelData.id)
                                    : ""
                            }
                        }
                    }
                }

                Text {
                    id: name
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: row.bottom
                    anchors.topMargin: 4
                    text: root.hoveredName
                    color: Theme.muted
                    font.family: Theme.font
                    renderType: Text.NativeRendering
                    font.hintingPreference: Theme.hinting
                    font.pixelSize: 13
                }
            }
        }

        // 面板收起时把悬停名清掉,否则下次展开会先闪一下上次那条
        onActiveChanged: if (!active) root.hoveredName = ""
    }
}
