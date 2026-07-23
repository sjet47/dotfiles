#!/bin/bash
# 在指定显示器上 toggle special workspace(scratchpad)。
#
# Hyprland 的 special workspace 永远在"当前 focus 的那块屏"打开,monitor
# workspace-rule 对它无效(设计如此,非 bug)。这里先把焦点移到目标屏再
# toggle,保证 scratchpad 始终固定出现在该屏,而不是跟着焦点跑到副屏。
#
# 注意:Hyprland 0.55 起 hyprctl dispatch 的参数按 lua 解析,必须传
# dispatcher 表达式(hl.dsp.*),不能再用 "focusmonitor DP-1" 这类旧写法。
#
# 用法: scratchpad.sh <monitor> [special-name]
mon="${1:?usage: $0 <monitor> [special-name]}"
name="${2:-scratchpad}"

hyprctl --batch "dispatch hl.dsp.focus({ monitor = \"$mon\" }) ; dispatch hl.dsp.workspace.toggle_special(\"$name\")"
