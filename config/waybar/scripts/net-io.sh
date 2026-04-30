#!/usr/bin/env bash
INTERVAL=2

sample() {
    awk '$1 !~ /^(lo:|virbr|docker|veth|br-|tun|tap)/ {rx+=$2; tx+=$10} END{print rx, tx}' /proc/net/dev
}

# 动态单位：B/s, KiB/s, MiB/s
fmt() {
    awk -v b="$1" -v t="$INTERVAL" 'BEGIN{
        bps = b/t
        if (bps < 1024)        printf "%dB",     bps
        else if (bps < 1048576) printf "%.0fK", bps/1024
        else                    printf "%.1fM", bps/1048576
    }'
}

read rx1 tx1 < <(sample)
sleep "$INTERVAL"
read rx2 tx2 < <(sample)

up=$(fmt $((tx2 - tx1)))
down=$(fmt $((rx2 - rx1)))

printf '󰓡 ↑%s ↓%s\n' "$up" "$down"
