#!/bin/bash
# 截图：smart(默认) / region / window / fullscreen / active(当前窗口,不框选) / qr(框选解码二维码)
# 自动 wl-copy + 落盘到 ~/Pictures，通知点击打开 tensaku 标注（回车=存盘+复制）
# 第二个参数传 save：只落盘并把路径打到 stdout，不碰剪贴板、不弹通知（供 agent 等非交互调用）
# 移植自 omarchy-cmd-screenshot

set -u

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$OUTPUT_DIR"

MODE="${1:-smart}"
OUTPUT="${2:-}"

# 再次触发同一脚本时取消正在进行的选区；save 是非交互调用，不应打断用户手上的框选
if [[ $OUTPUT != "save" ]]; then
  pkill slurp && exit 0
fi

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

PID=""
cleanup_freeze() { [[ -n $PID ]] && kill "$PID" 2>/dev/null; }
trap cleanup_freeze EXIT

freeze() {
  hyprpicker -r -z >/dev/null 2>&1 &
  PID=$!
  sleep .1
}

case "$MODE" in
  qr)
    # 框选区域解码二维码/条码,结果进剪贴板(不落盘)
    freeze
    SELECTION=$(slurp 2>/dev/null)
    [[ -z ${SELECTION:-} ]] && exit 0
    TMP=$(mktemp --suffix=.png)
    grim -g "$SELECTION" "$TMP" || { rm -f "$TMP"; exit 1; }
    CODE=$(zbarimg --raw -q "$TMP" 2>/dev/null)
    rm -f "$TMP"
    if [[ -z $CODE ]]; then
      notify-send -t 4000 "未识别到二维码/条码" "试试放大后再框选"
    else
      printf '%s' "$CODE" | wl-copy
      notify-send -t 6000 "二维码已解码并复制" "$CODE"
    fi
    exit 0
    ;;
  region)
    freeze
    SELECTION=$(slurp 2>/dev/null)
    ;;
  window)
    freeze
    SELECTION=$(get_rectangles | slurp -r 2>/dev/null)
    ;;
  fullscreen)
    SELECTION=$(hyprctl monitors -j | jq -r "${JQ_MONITOR_GEO} .[] | select(.focused == true) | format_geo")
    ;;
  active)
    SELECTION=$(hyprctl activewindow -j | jq -r 'select(.at) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
    [[ -z $SELECTION ]] && { echo "当前没有活动窗口" >&2; exit 1; }
    ;;
  smart|*)
    RECTS=$(get_rectangles)
    freeze
    SELECTION=$(echo "$RECTS" | slurp 2>/dev/null)
    # <20px² 视为误点，吸附到所在窗口/显示器
    if [[ $SELECTION =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]]; then
      if ((BASH_REMATCH[3] * BASH_REMATCH[4] < 20)); then
        cx="${BASH_REMATCH[1]}"; cy="${BASH_REMATCH[2]}"
        while IFS= read -r rect; do
          if [[ $rect =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+) ]]; then
            rx="${BASH_REMATCH[1]}"; ry="${BASH_REMATCH[2]}"
            rw="${BASH_REMATCH[3]}"; rh="${BASH_REMATCH[4]}"
            if ((cx >= rx && cx < rx + rw && cy >= ry && cy < ry + rh)); then
              SELECTION="${rx},${ry} ${rw}x${rh}"
              break
            fi
          fi
        done <<<"$RECTS"
      fi
    fi
    ;;
esac

[[ -z ${SELECTION:-} ]] && exit 0

BASE="$OUTPUT_DIR/Screenshot_$(date +'%Y%m%d_%H%M%S')"
FILEPATH="$BASE.png"
# 时间戳精确到秒，同一秒内的连续截图（如改动前后对比）需要错开文件名
n=2
while [[ -e $FILEPATH ]]; do
  FILEPATH="${BASE}_$n.png"
  n=$((n + 1))
done

grim -g "$SELECTION" "$FILEPATH" || exit 1

if [[ $OUTPUT == "save" ]]; then
  echo "$FILEPATH"
  exit 0
fi

wl-copy <"$FILEPATH"

(
  ACTION=$(notify-send "截图已保存并复制到剪贴板" "点击用 tensaku 标注\n$FILEPATH" \
    -t 8000 -i "$FILEPATH" -A "default=标注")
  [[ $ACTION == "default" ]] && tensaku \
    --filename "$FILEPATH" \
    --output-filename "$FILEPATH" \
    --actions-on-enter save-to-clipboard \
    --save-after-copy \
    --copy-command 'wl-copy'
) &
