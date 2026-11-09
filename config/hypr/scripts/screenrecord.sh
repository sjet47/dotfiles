#!/bin/bash
# 录屏：region(默认,拉框) / window / fullscreen
# 用 wl-screenrec(VAAPI 硬件编码)录制到 ~/Videos/Screencasts，再次触发=停止并落盘
# mp4 < 5MiB 时额外生成同名 GIF 并复制到剪贴板
# 选区逻辑复用自 screenshot.sh；录屏需实时画面，故不冻结(无 hyprpicker)

set -u

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Screencasts"
mkdir -p "$OUTPUT_DIR"

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/screenrecord.path"

GIF_MAX_MP4_BYTES=$((5 * 1024 * 1024))
GIF_FPS=15
GIF_MAX_WIDTH=1280

# mp4 小于阈值时,在旁边生成同名 GIF 并放进剪贴板
make_gif_and_copy() {
  local mp4=$1 gif="${1%.mp4}.gif" size
  size=$(stat -c %s "$mp4" 2>/dev/null) || return
  # size>0:录制异常中断会留下 0 字节文件
  ((size > 0 && size < GIF_MAX_MP4_BYTES)) || return

  local filter="fps=$GIF_FPS,scale='min($GIF_MAX_WIDTH,iw)':-2:flags=lanczos,split[a][b];"
  filter+="[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle"
  if ffmpeg -nostdin -v error -y -i "$mp4" -filter_complex "$filter" "$gif"; then
    # Chromium 系只读 image/png 和 text/uri-list,按文件粘贴才能保住动图
    python3 -c 'import pathlib, sys; sys.stdout.write(pathlib.Path(sys.argv[1]).as_uri() + "\r\n")' "$gif" |
      wl-copy --type text/uri-list
    notify-send "GIF 已复制到剪贴板" "$gif" -t 5000
  else
    rm -f "${gif:?}"
    notify-send "GIF 转换失败" "$mp4" -u critical
  fi
}

# 已在录制 -> 停止(SIGINT 让 wl-screenrec 正常收尾落盘)并通知
if pgrep -x wl-screenrec >/dev/null; then
  pkill -INT -x wl-screenrec
  # 进程退出后 mp4 才写完,此前大小不准、ffmpeg 也读不了;最多等 10 秒
  for _ in {1..100}; do
    pgrep -x wl-screenrec >/dev/null || break
    sleep 0.1
  done
  FILEPATH=$(cat "$STATE_FILE" 2>/dev/null)
  rm -f "$STATE_FILE"
  if [[ -n ${FILEPATH:-} ]]; then
    (
      ACTION=$(notify-send "录屏已保存" "$FILEPATH" -t 8000 -A "default=打开")
      [[ $ACTION == "default" ]] && xdg-open "$FILEPATH"
    ) &
    make_gif_and_copy "$FILEPATH"
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
