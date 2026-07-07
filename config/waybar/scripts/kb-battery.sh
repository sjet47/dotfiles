#!/usr/bin/env bash
# 读取蓝牙键盘剩余电量，输出 waybar JSON。键盘未连接时输出空对象以隐藏模块。
set -euo pipefail

dev=$(upower -e 2>/dev/null | grep -m1 keyboard || true)
[ -z "$dev" ] && { echo '{}'; exit 0; }

info=$(upower -i "$dev" 2>/dev/null || true)
pct=$(printf '%s\n' "$info" | awk '/percentage:/ {gsub(/%/,"",$2); print int($2); exit}')
[ -z "${pct:-}" ] && { echo '{}'; exit 0; }

model=$(printf '%s\n' "$info" | awk -F': +' '/model:/ {print $2; exit}')

# 10 级电池图标（与 waybar battery 模块一致的 nerd font 图标）
icons=(󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)
idx=$(( pct / 10 ))
[ "$idx" -gt 9 ] && idx=9
icon="${icons[$idx]}"

class="normal"
if [ "$pct" -le 10 ]; then class="critical"
elif [ "$pct" -le 20 ]; then class="warning"; fi

printf '{"text":"%s %d%%","tooltip":"%s: %d%%","class":"%s"}\n' \
  "$icon" "$pct" "${model:-Keyboard}" "$pct" "$class"
