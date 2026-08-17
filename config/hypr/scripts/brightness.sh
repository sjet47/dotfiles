#!/usr/bin/env bash
# 亮度调节,作用于当前聚焦的显示器:
#   内屏(eDP/LVDS/DSI) → brightnessctl;外接显示器 → DDC/CI (ddcutil)
# 用法: brightness.sh up|down [step]   step 为 DDC 每步百分点,默认 10
#
# 连接器 → i2c 总线映射用 ddcutil detect 结果做缓存(detect 较慢 ~2s);
# 不能用 /sys/class/drm/*/ddc 符号链接:DP 的 DDC 走 AUX 通道,sysfs 指向的总线不对。
set -uo pipefail

STEP=${2:-10}
case "${1:-}" in
  up)   OP="+"; BCTL="5%+" ;;
  down) OP="-"; BCTL="5%-" ;;
  *) echo "usage: $0 up|down [step]" >&2; exit 1 ;;
esac

mon=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

if [[ $mon == eDP* || $mon == LVDS* || $mon == DSI* ]]; then
  exec brightnessctl -e4 -n2 set "$BCTL"
fi

# DDC 写入较慢(~200ms),flock -n 丢弃按住连发时的重叠触发
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/ddc-brightness.lock"
flock -n 9 || exit 0

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ddc-bus-map"

refresh_map() {
  ddcutil detect --brief 2>/dev/null | awk '
    /I2C bus:/      { bus = $NF; sub(".*i2c-", "", bus) }
    /DRM connector:/ { print $NF, bus }
  ' >"$CACHE"
}

# 缓存里连接器名形如 card1-HDMI-A-1,按 "-<监视器名>" 后缀匹配
lookup() {
  awk -v m="-$mon" 'index($1, m) == length($1) - length(m) + 1 { print $2; exit }' "$CACHE" 2>/dev/null
}

bus=$(lookup)
if [ -z "$bus" ] || ! ddcutil setvcp 10 "$OP" "$STEP" --bus "$bus" --noverify 2>/dev/null; then
  refresh_map
  bus=$(lookup)
  [ -n "$bus" ] && ddcutil setvcp 10 "$OP" "$STEP" --bus "$bus" --noverify
fi
