#!/usr/bin/env bash
# 蓝牙键盘电量,事件驱动:启动时输出一次,之后跟随 upower 事件更新,无轮询。
# 作为 waybar custom 模块的常驻进程运行(不配 interval):每输出一行即刷新一次。
set -uo pipefail

emit() {
  local dev info pct model idx class
  dev=$(upower -e 2>/dev/null | grep -m1 keyboard || true)
  [ -z "$dev" ] && { echo '{}'; return; }

  info=$(upower -i "$dev" 2>/dev/null || true)
  pct=$(printf '%s\n' "$info" | awk '/percentage:/ {gsub(/%/,"",$2); print int($2); exit}')
  [ -z "${pct:-}" ] && { echo '{}'; return; }

  model=$(printf '%s\n' "$info" | awk -F': +' '/model:/ {print $2; exit}')

  # 10 级电池图标（与 waybar battery 模块一致的 nerd font 图标）
  local icons=(󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)
  idx=$(( pct / 10 ))
  [ "$idx" -gt 9 ] && idx=9

  class="normal"
  if [ "$pct" -le 10 ]; then class="critical"
  elif [ "$pct" -le 20 ]; then class="warning"; fi

  printf '{"text":"%s %d%%","tooltip":"%s: %d%%","class":"%s"}\n' \
    "${icons[$idx]}" "$pct" "${model:-Keyboard}" "$pct" "$class"
}

emit

# 只关心键盘设备的 added/removed/changed 事件;stdbuf 防止管道块缓冲延迟事件
stdbuf -oL upower --monitor 2>/dev/null | while IFS= read -r line; do
  case "$line" in
    *keyboard*) emit ;;
  esac
done
