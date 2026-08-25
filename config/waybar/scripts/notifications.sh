#!/usr/bin/env bash
# waybar 通知模块的后端。守护进程是 quickshell(config/quickshell/,单实例 `qs`),
# 原来是 mako —— 字段名也跟着变了(mako 的 app_name → appName)。
#
#   status   打印图标,免打扰时换成带斜杠的铃铛(mako 时代没有这个反馈)
#   dnd      切免打扰,并发 RTMIN+1 让 waybar 立刻刷新图标
#   history  历史消息丢给 vicinae dmenu

set -uo pipefail

qs_call() { qs ipc call notif "$@" 2>/dev/null; }

case "${1:-status}" in
status)
  [[ $(qs_call dndStatus) == on ]] && echo "󰂛" || echo "󰂚"
  ;;

dnd)
  qs_call dndToggle >/dev/null
  pkill -RTMIN+1 waybar
  ;;

history)
  # body 里可能有真换行,dmenu 一行一条,先压平
  list=$(qs_call history | jq -r '
    if length == 0 then "（无历史消息）"
    else .[] | "[\(.appName // "?")] \(.summary // "") — \((.body // "") | gsub("\n"; " "))"
    end')
  [[ -z $list ]] && list="（无历史消息）"
  echo "$list" | vicinae dmenu --section-title="通知历史({count})" --width=720 --no-footer >/dev/null
  ;;

*)
  echo "usage: $0 status|dnd|history" >&2
  exit 1
  ;;
esac
