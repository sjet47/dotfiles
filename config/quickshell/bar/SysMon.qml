//
// CPU + 内存(= waybar 的 cpu / memory 两个模块)。
//
// 文本和点击行为 1:1 复刻;**悬浮详情面板是这次刻意新增的**(用户 2026-08-27 决定):
// waybar 的 tooltip 只能是一根格式化字符串,想画逐核占用就得另起一个窗口 —— 这也是
// 这次迁移的直接动机之一。数据来自 SysInfo.qml(每 2s 一次,与 waybar 的 interval 一致)。
//
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Row {
    id: root
    spacing: 0

    BarItem {                                       // #cpu
        marginLeft: 0                               // 左边界由 Bar.qml 的分隔线负责
        // on-click / on-click-right 照抄 config.jsonc
        onClicked: b => Quickshell.execDetached(b === Qt.RightButton
            ? ["kitty"]
            : ["kitty", "--class", "btop-float", "-e", "btop"])

        Text {
            text: "󰍛 " + Math.round(SysInfo.cpuUsage * 100) + "%"
            font.family: Theme.font
            renderType: Text.NativeRendering
            font.hintingPreference: Theme.hinting
            font.pixelSize: Theme.fontSize
            font.features: ({ "tnum": 1 })          // 百分比跳动时整条栏不左右抖
            color: Theme.fg
        }

        tooltipItem: Component {
            Column {
                spacing: 8

                Text {
                    text: "CPU  " + Math.round(SysInfo.cpuUsage * 100) + "%  ·  "
                          + SysInfo.coreUsage.length + " 线程"
                    color: Theme.fg
                    font.family: Theme.font
                    renderType: Text.NativeRendering
                    font.hintingPreference: Theme.hinting
                    font.pixelSize: 14
                }

                // 逐核柱状图:每核一根竖条,8 根一行
                Grid {
                    columns: 8
                    spacing: 4

                    Repeater {
                        model: SysInfo.coreUsage

                        Rectangle {
                            required property var modelData
                            required property int index

                            width: 12
                            height: 34
                            radius: 3
                            color: "#1affffff"

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: Math.max(2, parent.height * modelData)
                                radius: parent.radius
                                // 高负载变黄再变红,跟 waybar 的 warning/critical 同色
                                color: modelData > 0.9 ? Theme.critical
                                       : modelData > 0.7 ? Theme.warning : Theme.fg
                                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                Behavior on color  { ColorAnimation  { duration: 300 } }
                            }
                        }
                    }
                }
            }
        }
    }

    BarItem {                                       // #memory
        id: mem

        Text {
            // format: "󰘚 {used:0.1f}G/{percentage}%"
            text: "󰘚 " + SysInfo.memUsedGiB.toFixed(1) + "G/" + Math.round(SysInfo.memRatio * 100) + "%"
            font.family: Theme.font
            renderType: Text.NativeRendering
            font.hintingPreference: Theme.hinting
            font.pixelSize: Theme.fontSize
            font.features: ({ "tnum": 1 })
            color: Theme.fg
        }

        tooltipItem: Component {
            Column {
                spacing: 6

                Text {
                    // tooltip-format: "{used:0.1f}/{total:0.1f}G"
                    text: SysInfo.memUsedGiB.toFixed(1) + " / " + SysInfo.memTotalGiB.toFixed(1) + " GiB"
                    color: Theme.fg
                    font.family: Theme.font
                    renderType: Text.NativeRendering
                    font.hintingPreference: Theme.hinting
                    font.pixelSize: 14
                }

                Rectangle {
                    width: 200
                    height: 6
                    radius: 3
                    color: "#1affffff"

                    Rectangle {
                        width: parent.width * SysInfo.memRatio
                        height: parent.height
                        radius: parent.radius
                        color: SysInfo.memRatio > 0.9 ? Theme.critical
                               : SysInfo.memRatio > 0.7 ? Theme.warning : Theme.fg
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }
}
