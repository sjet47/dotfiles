#!/bin/bash
# 截图：smart(默认) / region / window / fullscreen
# 自动 wl-copy + 落盘到 ~/Pictures，通知点击打开 ksnip 编辑
# 移植自 omarchy-cmd-screenshot，编辑器换成 ksnip

set -u

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${OMARCHY_SCREENSHOT_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}}"
mkdir -p "$OUTPUT_DIR"

# 再次触发同一脚本时取消正在进行的选区
pkill slurp && exit 0

MODE="${1:-smart}"

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

FILEPATH="$OUTPUT_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
grim -g "$SELECTION" "$FILEPATH" || exit 1
wl-copy <"$FILEPATH"

(
  ACTION=$(notify-send "截图已保存并复制到剪贴板" "点击编辑\n$FILEPATH" \
    -t 8000 -i "$FILEPATH" -A "default=编辑")
  [[ $ACTION == "default" ]] && ksnip -e "$FILEPATH"
) &
