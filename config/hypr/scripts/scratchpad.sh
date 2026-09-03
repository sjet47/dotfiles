#!/bin/bash
# 在指定显示器上 toggle special workspace(scratchpad),或把当前窗口丢进去。
#
# Hyprland 的 special workspace 永远在"当前 focus 的那块屏"打开,monitor
# workspace-rule 对它无效(设计如此,非 bug)。这里先把焦点移到目标屏再
# toggle,保证 scratchpad 始终固定出现在该屏,而不是跟着焦点跑到副屏。
#
# move 模式同理:原生 movetoworkspace 会让 special 在"被移动窗口所在的那块屏"
# 亮出来。所以先按 toggle 模式把它开在目标屏,再用 address 定向移动窗口 ——
# 不能反过来先 focus 目标屏,那样焦点一换就不知道该移哪个窗口了。
#
# 注意:Hyprland 0.55 起 hyprctl dispatch 的参数按 lua 解析,必须传
# dispatcher 表达式(hl.dsp.*),不能再用 "focusmonitor DP-1" 这类旧写法。
#
# 用法: scratchpad.sh <monitor> [special-name] [move]
mon="${1:?usage: $0 <monitor> [special-name] [move]}"
name="${2:-scratchpad}"
mode="${3:-toggle}"

show() {
  hyprctl --batch "dispatch hl.dsp.focus({ monitor = \"$mon\" }) ; dispatch hl.dsp.workspace.toggle_special(\"$name\")"
}

if [[ "$mode" != "move" ]]; then
  show
  exit
fi

addr=$(hyprctl activewindow -j | jq -r '.address // empty')
[[ -z "$addr" ]] && exit 0

# 已经开在目标屏就别再 toggle,那会把它关掉。
cur=$(hyprctl monitors -j | jq -r --arg m "$mon" '.[] | select(.name == $m) | .specialWorkspace.name')
[[ "$cur" != "special:$name" ]] && show

# 焦点跟着窗口走,与原生 movetoworkspace 的手感一致。
hyprctl --batch "dispatch hl.dsp.window.move({ window = \"address:$addr\", workspace = \"special:$name\" }) ; dispatch hl.dsp.focus({ window = \"address:$addr\" })"
