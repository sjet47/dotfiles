#!/usr/bin/env bash
# 亮度调节,作用于当前聚焦的显示器:
#   内屏(eDP/LVDS/DSI) → brightnessctl;外接显示器 → DDC/CI (ddcutil)
# 用法: brightness.sh up|down [step]   step 为 DDC 每步百分点,默认 10
#
# 调完会把新百分比推给 quickshell OSD(config/quickshell/osd)。DDC 没有便宜的读取方式
# (getvcp 一次 ~200ms),所以只在缓存缺失时读一次,之后按 STEP 本地累加。
# 代价:用显示器物理按键改过亮度后缓存会漂,删掉 $XDG_RUNTIME_DIR/ddc-level-* 即可重新播种。
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

# 推给 OSD;没装 quickshell 或 OSD 没跑都不影响亮度调节本身
osd() { command -v qs >/dev/null 2>&1 && qs ipc call osd brightness "$1" >/dev/null 2>&1 & }

if [[ $mon == eDP* || $mon == LVDS* || $mon == DSI* ]]; then
  brightnessctl -e4 -n2 set "$BCTL" >/dev/null
  osd "$(brightnessctl -m | cut -d, -f4 | tr -d '%')"
  exit 0
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
  [ -n "$bus" ] || exit 0
  ddcutil setvcp 10 "$OP" "$STEP" --bus "$bus" --noverify || exit 0
fi

# 维护当前百分比给 OSD 用
LVL="${XDG_RUNTIME_DIR:-/tmp}/ddc-level-$mon"
cur=$(cat "$LVL" 2>/dev/null)
if [ -n "$cur" ]; then
  # 缓存存的是本次调整"之前"的值,累加得到新值
  new=$((cur $OP STEP))
else
  # 缓存缺失:此刻 setvcp 已生效,getvcp 读到的就是新值,不能再累加
  new=$(ddcutil getvcp 10 --bus "$bus" --brief 2>/dev/null | awk '{print $4}')
fi
if [ -n "$new" ]; then
  [ "$new" -lt 0 ]   && new=0
  [ "$new" -gt 100 ] && new=100
  echo "$new" >"$LVL"
  osd "$new"
fi
