#!/usr/bin/env bash
# 股票报价（Yahoo Finance，含盘前/盘中/盘后），支持多支一次拉取
# 用法: stock.sh <sym1> [sym2 ...]      例: stock.sh MU NVDA TSLA
#   显示: 红涨绿跌(A股习惯)，箭头表方向，百分比取绝对值
#   注: Yahoo 个股只覆盖 盘前(约4:00 ET)/盘中/盘后(至20:00 ET)，无 24h 夜盘
SYMS="$*"
[ -z "$SYMS" ] && SYMS="MU"
CSV=$(printf '%s' "$SYMS" | tr ' ' ',')
UA="Mozilla/5.0"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-stock"
CK="$CACHE_DIR/cookies.txt"
CRUMB_F="$CACHE_DIR/crumb"
LAST="$CACHE_DIR/last.json"
mkdir -p "$CACHE_DIR"

err() { printf '{"text":"  --","tooltip":"%s"}\n' "$1"; exit 0; }

# Yahoo 个股仅在 美东 周一至周五 04:00–20:00（盘前/盘中/盘后）有实时数据；
# 夜盘/周末无新数据：有缓存就复用上次结果并跳过网络请求省开销，无缓存则照常跑一次
# 以便首次也能拿到收盘价（TZ 自动处理夏令时）
read -r DOW HM < <(TZ="America/New_York" date '+%u %H%M'); HM=$((10#$HM))
if { [ "$DOW" -ge 6 ] || [ "$HM" -lt 400 ] || [ "$HM" -ge 2000 ]; } && [ -s "$LAST" ]; then
    cat "$LAST"; exit 0
fi

auth() {
    curl -fsS -A "$UA" -c "$CK" -o /dev/null "https://fc.yahoo.com" 2>/dev/null
    curl -fsS -A "$UA" -b "$CK" "https://query1.finance.yahoo.com/v1/test/getcrumb" 2>/dev/null >"$CRUMB_F"
}

fetch() {
    local crumb
    crumb=$(cat "$CRUMB_F" 2>/dev/null)
    [ -z "$crumb" ] && return 1
    curl -fsS -A "$UA" -b "$CK" \
        "https://query1.finance.yahoo.com/v7/finance/quote?symbols=${CSV}&crumb=${crumb}" 2>/dev/null
}

# 先用缓存 cookie+crumb；失效则重新鉴权再试一次
data=$(fetch)
if ! jq -e '.quoteResponse.result[0].regularMarketPrice' >/dev/null 2>&1 <<<"$data"; then
    auth
    data=$(fetch)
fi
jq -e '.quoteResponse.result[0].regularMarketPrice' >/dev/null 2>&1 <<<"$data" || err "stock fetch failed"

# 每支输出一行 TSV: symbol \t state \t price \t pct（已按时段选价，缺失回退盘中）
parsed=$(jq -r '
    .quoteResponse.result[] |
    .marketState as $s |
    (if   $s=="PRE"               then .preMarketPrice
     elif ($s=="POST" or $s=="POSTPOST") then .postMarketPrice
     else .regularMarketPrice end) as $p0 |
    (if   $s=="PRE"               then .preMarketChangePercent
     elif ($s=="POST" or $s=="POSTPOST") then .postMarketChangePercent
     else .regularMarketChangePercent end) as $c0 |
    (if ($p0==null or $p0==0) then .regularMarketPrice          else $p0 end) as $p |
    (if ($p0==null or $p0==0) then .regularMarketChangePercent  else $c0 end) as $c |
    [ .symbol, $s, ($p // 0), ($c // 0) ] | @tsv
' <<<"$data")

text=""
tip=""
while IFS=$'\t' read -r sym state price pct; do
    [ -z "$sym" ] && continue
    pr=$(awk -v p="$price" 'BEGIN{printf "%.2f", p}')
    absp=$(awk -v p="$pct" 'BEGIN{printf "%.2f", (p<0)?-p:p}')
    if awk -v p="$pct" 'BEGIN{exit !(p+0>=0)}'; then
        arrow="▲"; color="#ff453a"
    else
        arrow="▼"; color="#30d158"
    fi
    seg=$(printf '%s <span foreground="%s">%s%s</span>' "$sym" "$color" "$arrow" "$pr")
    text="${text:+$text  }$seg"
    tip="${tip:+$tip$'\n'}$(printf '%s  [%s]  %s  %s%s%%' "$sym" "$state" "$pr" "$arrow" "$absp")"
done <<<"$parsed"

[ -z "$text" ] && err "stock parse failed"

jq -cn --arg t "$text" --arg tip "$tip" '{text:$t, tooltip:$tip}' | tee "$LAST"
