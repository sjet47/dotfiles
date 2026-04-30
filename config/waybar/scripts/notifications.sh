#!/usr/bin/env bash
# 列出 mako 历史消息到 wofi
list=$(makoctl history -j 2>/dev/null | jq -r '
  if length == 0 then "（无历史消息）"
  else
    .[] | "[\(.app_name // "?")] \(.summary // "") — \(.body // "")"
  end
')

[[ -z "$list" ]] && list="（无历史消息）"

echo "$list" | vicinae dmenu --section-title="通知历史({count})" --width=720 --no-footer >/dev/null
