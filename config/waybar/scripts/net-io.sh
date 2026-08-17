#!/usr/bin/env bash
# 网络吞吐,常驻进程版:每 INTERVAL 秒输出一行,纯 bash 无重复 fork。
INTERVAL=2

# 汇总 /proc/net/dev 收发字节数(跳过 lo 和虚拟网卡),结果放入 RX/TX
sample() {
  RX=0 TX=0
  local line name fields
  while IFS= read -r line; do
    [[ $line != *:* ]] && continue
    name=${line%%:*}; name=${name// /}
    case "$name" in lo|virbr*|docker*|veth*|br-*|tun*|tap*) continue ;; esac
    read -r -a fields <<<"${line#*:}"
    RX=$((RX + fields[0])); TX=$((TX + fields[8]))
  done </proc/net/dev
}

# 动态单位 B/K/M,printf -v 写入变量避免子 shell
fmt() {
  local -n out=$1
  local bps=$(( $2 / INTERVAL ))
  if (( bps < 1024 )); then printf -v out '%dB' "$bps"
  elif (( bps < 1048576 )); then printf -v out '%dK' $(( bps / 1024 ))
  else printf -v out '%d.%dM' $(( bps / 1048576 )) $(( bps % 1048576 * 10 / 1048576 )); fi
}

sample; rx0=$RX tx0=$TX
while sleep "$INTERVAL"; do
  sample
  fmt up $((TX - tx0)); fmt down $((RX - rx0))
  printf '󰓡 ↑%s ↓%s\n' "$up" "$down"
  rx0=$RX tx0=$TX
done
