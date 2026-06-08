#!/bin/bash
# 录屏：region(默认,拉框) / window / fullscreen
# 用 wl-screenrec(VAAPI 硬件编码)录制到 ~/Videos，再次触发=停止并落盘
# 选区逻辑复用自 screenshot.sh；录屏需实时画面，故不冻结(无 hyprpicker)

set -u

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}"
mkdir -p "$OUTPUT_DIR"

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/screenrecord.path"

# 已在录制 -> 停止(SIGINT 让 wl-screenrec 正常收尾落盘)并通知
if pgrep -x wl-screenrec >/dev/null; then
  pkill -INT -x wl-screenrec
  FILEPATH=$(cat "$STATE_FILE" 2>/dev/null)
  rm -f "$STATE_FILE"
  if [[ -n ${FILEPATH:-} ]]; then
    (
      ACTION=$(notify-send "录屏已保存" "$FILEPATH" -t 8000 -A "default=打开")
      [[ $ACTION == "default" ]] && xdg-open "$FILEPATH"
    ) &
  fi
  exit 0
fi

# 再次触发同一脚本时取消正在进行的选区
pkill slurp && exit 0

MODE="${1:-region}"

JQ_MONITOR_GEO='
  def format_geo:
    .x as $x | .y as $y |
    (.width / .scale | floor) as $w |
    (.height / .scale | floor) as $h |
    .transform as $t |
    if $t == 1 or $t == 3 then
      "\($x),\($y) \($h)x\($w)"
    else
      "\($x),\($y) \($w)x\($h)"
    end;
'

get_rectangles() {
  local active_workspace
  active_workspace=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .activeWorkspace.id')
  hyprctl monitors -j | jq -r --arg ws "$active_workspace" "${JQ_MONITOR_GEO} .[] | select(.activeWorkspace.id == (\$ws | tonumber)) | format_geo"
  hyprctl clients -j | jq -r --arg ws "$active_workspace" '.[] | select(.workspace.id == ($ws | tonumber)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

GEO_ARGS=()
SELECTION=""   # 区域/窗口模式下非空,用于画范围边框;整屏模式留空
case "$MODE" in
  window)
    SELECTION=$(get_rectangles | slurp -r 2>/dev/null)
    [[ -z ${SELECTION:-} ]] && exit 0
    GEO_ARGS=(-g "$SELECTION")
    ;;
  fullscreen)
    MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
    [[ -z ${MONITOR:-} ]] && exit 1
    GEO_ARGS=(-o "$MONITOR")
    ;;
  region|*)
    SELECTION=$(slurp 2>/dev/null)
    [[ -z ${SELECTION:-} ]] && exit 0
    GEO_ARGS=(-g "$SELECTION")
    ;;
esac

FILEPATH="$OUTPUT_DIR/Screenrecording_$(date +'%Y%m%d_%H%M%S').mp4"
echo "$FILEPATH" >"$STATE_FILE"

# 区域/窗口模式:在选区外圈画范围边框(点击穿透,不进入录像)
OVERLAY_PID=""
if [[ -n $SELECTION && $SELECTION =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]([0-9]+)x([0-9]+) ]]; then
  python3 ~/.config/hypr/scripts/recording-border.py \
    "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}" &
  OVERLAY_PID=$!
fi

notify-send "开始录屏" "再次按下快捷键停止并保存\n$FILEPATH" -t 3000
wl-screenrec "${GEO_ARGS[@]}" -f "$FILEPATH"

# wl-screenrec 收到 SIGINT 退出后,清掉范围边框
[[ -n $OVERLAY_PID ]] && kill "$OVERLAY_PID" 2>/dev/null
