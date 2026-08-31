#!/usr/bin/env bash
# Claude Code 订阅用量,常驻进程:默认每 15 分钟探测一次 Anthropic OAuth usage 端点,
# 文本显示 5 小时会话窗口百分比,tooltip 含周限额与重置时间。
# 收到 SIGUSR1 立即刷新(on-click 触发)。
# 鉴权与 payload 结构参考 omarchy bin/omarchy-agent-usage-claude。
set -uo pipefail

INTERVAL=900
CRED="$HOME/.claude/.credentials.json"
ENDPOINT="https://api.anthropic.com/api/oauth/usage"
# 图标由 style.css 以背景图方式渲染 (icons/claude.svg),文本只输出数值

LAST_JSON=""   # 上次成功的输出;探测失败时回放并在 tooltip 标注 stale
LAST_AT=""

plan_label() {
  local tier sub
  tier=$(jq -r '.claudeAiOauth.rateLimitTier // ""' "$CRED" 2>/dev/null)
  sub=$(jq -r '.claudeAiOauth.subscriptionType // ""' "$CRED" 2>/dev/null)
  if [[ $tier =~ [Mm]ax_([0-9]+x) ]]; then
    echo "Max ${BASH_REMATCH[1]}"
  elif [[ -n $sub ]]; then
    echo "${sub^}"
  fi
}

fmt_reset() {
  # "-" 是 jq 侧的空值哨兵:空字符串会被 read 的 IFS 折叠导致字段错位
  [[ -z $1 || $1 == "-" ]] && { echo "?"; return; }
  date -d "$1" '+%m-%d %H:%M' 2>/dev/null || echo "$1"
}

emit() {
  local token payload
  EMIT_OK=0
  token=$(jq -r '.claudeAiOauth.accessToken // empty' "$CRED" 2>/dev/null)
  if [[ -z $token ]]; then
    echo '{}'
    return
  fi

  payload=$(curl -sf --max-time 10 \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "Accept: application/json" \
    "$ENDPOINT" 2>/dev/null) || payload=""

  if [[ -z $payload ]]; then
    if [[ -n $LAST_JSON ]]; then
      jq -c --arg note "⚠ 探测失败,数据截至 $LAST_AT" \
        '.tooltip += "\n" + $note' <<<"$LAST_JSON"
    else
      printf '{"text":"?","tooltip":"Claude 用量探测失败(离线或 token 过期,跑一次 claude 可刷新登录)\\n点击重试"}\n'
    fi
    return
  fi

  # utilization 新 payload 为百分数(37.0),旧的可能是小数(0.37):任一值 >= 1 即按百分数处理
  local s_pct w_pct s_reset w_reset
  IFS=$'\t' read -r s_pct w_pct s_reset w_reset < <(jq -r '
    def raw: if . == null then -1 else (tostring | gsub("%|\\s";"") | tonumber? // -1) end;
    (.seven_day_oauth_apps // .seven_day // {}) as $w | (.five_hour // {}) as $s
    | ($s.utilization | raw) as $sr | ($w.utilization | raw) as $wr
    | (if $sr >= 1 or $wr >= 1 then 1 else 100 end) as $mul
    | [ (if $sr < 0 then -1 else ([$sr * $mul, 100] | min | round) end),
        (if $wr < 0 then -1 else ([$wr * $mul, 100] | min | round) end),
        ($s.resets_at // "-" | tostring), ($w.resets_at // "-" | tostring) ]
    | @tsv' <<<"$payload") || { echo '{}'; return; }

  if [[ $w_pct -lt 0 && $s_pct -lt 0 ]]; then
    printf '{"text":"?","tooltip":"usage 端点未返回限额数据"}\n'
    return
  fi

  local class="" plan title tooltip text
  (( s_pct >= 70 || w_pct >= 70 )) && class="warning"
  (( s_pct >= 90 || w_pct >= 90 )) && class="critical"

  plan=$(plan_label)
  title="Claude Code${plan:+ · $plan}"
  tooltip="$title"
  [[ $s_pct -ge 0 ]] && tooltip+="\n会话(5h): ${s_pct}% · 重置 $(fmt_reset "$s_reset")"
  [[ $w_pct -ge 0 ]] && tooltip+="\n周限额: ${w_pct}% · 重置 $(fmt_reset "$w_reset")"
  tooltip+="\n更新于 $(date '+%H:%M') · 点击刷新"

  # 文本优先展示 5h 会话窗口;端点只给了周数据时退回周限额
  if [[ $s_pct -ge 0 ]]; then text="${s_pct}%"; else text="${w_pct}%"; fi

  LAST_JSON=$(printf '{"text":"%s","tooltip":"%s","class":"%s","percentage":%d}' \
    "$text" "$tooltip" "$class" "$(( s_pct >= 0 ? s_pct : w_pct ))")
  LAST_AT=$(date '+%H:%M')
  EMIT_OK=1
  echo "$LAST_JSON"
}

trap ':' USR1   # 中断 wait,立即进入下一轮探测
while :; do
  emit
  # 探测失败(离线/429 限流/token 过期)时 60s 快速重试,成功则回到正常节奏
  (( EMIT_OK )) && next=$INTERVAL || next=60
  sleep "$next" &
  wait $! || kill $! 2>/dev/null   # 被信号打断时回收还在跑的 sleep
done
