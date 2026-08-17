#!/usr/bin/env bash
# 记忆/恢复窗口尺寸,按 "应用class:工作区id" 存取(借鉴 omarchy 4 的宽度记忆)
# 用法: winsize.sh save|restore
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
STATE="$STATE_DIR/winsizes.json"
mkdir -p "$STATE_DIR"
[ -s "$STATE" ] || echo '{}' >"$STATE"

win=$(hyprctl activewindow -j)
addr=$(jq -r '.address // empty' <<<"$win")
[ -z "$addr" ] && exit 0
key=$(jq -r '"\(.class):\(.workspace.id)"' <<<"$win")

case "${1:-}" in
  save)
    size=$(jq -c '{w: .size[0], h: .size[1]}' <<<"$win")
    tmp=$(mktemp)
    jq --arg k "$key" --argjson v "$size" '.[$k] = $v' "$STATE" >"$tmp" && mv "$tmp" "$STATE"
    notify-send -t 2000 "窗口尺寸已记忆" "$key → $(jq -r '"\(.w)×\(.h)"' <<<"$size")"
    ;;
  restore)
    v=$(jq -c --arg k "$key" '.[$k] // empty' "$STATE")
    [ -z "$v" ] && { notify-send -t 2000 "无记忆尺寸" "$key"; exit 0; }
    # 不带 relative 即绝对尺寸,作用于当前活动窗口
    hyprctl dispatch \
      "hl.dsp.window.resize({ x = $(jq -r .w <<<"$v"), y = $(jq -r .h <<<"$v") })"
    ;;
  *) echo "usage: $0 save|restore" >&2; exit 1 ;;
esac
