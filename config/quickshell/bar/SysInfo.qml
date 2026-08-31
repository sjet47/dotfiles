//
// CPU / 内存 / 网络吞吐的唯一采样点。
//
// 这三样是整条状态栏里 quickshell 没有原生服务、必须自己读的部分(其余模块都有
// Quickshell.Services.* 或 Quickshell.Networking 兜着)。合并成一个单例的理由:
// 三个模块共用一个 2s 定时器,而不是各起各的 —— 采样点错开的话,同一屏上 CPU 和
// 内存的数字会来自不同时刻,看着会各跳各的。
//
// 采样口径抄自被替换掉的 waybar 脚本,保证迁移前后数字对得上:
//   - 网络:/proc/net/dev,跳过 lo 和虚拟网卡,口径同 scripts/net-io.sh
//   - 内存:MemTotal - MemAvailable,口径同 waybar 的 memory 模块
//   - CPU:/proc/stat 的 busy/total 增量,顺带按核拆开(waybar 只给总量,
//          逐核数据是这次新增的悬浮详情要用的)
//
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int interval: 2000

    property real cpuUsage: 0        // 0..1,全核平均
    property var  coreUsage: []      // 每核 0..1,悬浮详情用
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property real memRatio: 0        // 0..1
    property real netRx: 0           // B/s
    property real netTx: 0

    // 上一次采样的累计值。CPU 是每核一个 [busy, total];网络是 [rx, tx] + 时间戳。
    property var _cpuPrev: ({})
    property var _netPrev: null

    // blockLoading:reload() 之后紧接着 text() 要能拿到新内容。/proc 下的文件 size 报 0,
    // 但按流读是有内容的,FileView 处理得了;真正会坑人的是异步 —— 不阻塞的话 text()
    // 拿到的是上一轮的快照,增量算出来永远是 0。
    FileView { id: stat;    path: "/proc/stat";    blockLoading: true }
    FileView { id: meminfo; path: "/proc/meminfo"; blockLoading: true }
    FileView { id: netdev;  path: "/proc/net/dev"; blockLoading: true }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sample()
    }

    function sample(): void {
        stat.reload();
        meminfo.reload();
        netdev.reload();
        root.readCpu(stat.text());
        root.readMem(meminfo.text());
        root.readNet(netdev.text());
    }

    function readCpu(text: string): void {
        const prev = root._cpuPrev;
        const next = {};
        const cores = [];

        for (const line of text.split("\n")) {
            if (!line.startsWith("cpu")) break;          // cpu* 行都在最前面,遇到别的就收工
            const f = line.split(/\s+/);
            const key = f[0];                             // "cpu" 或 "cpu0"/"cpu1"...
            // user nice system idle iowait irq softirq steal —— idle 口径含 iowait,
            // 跟 waybar 一致(否则等 IO 的时间会被算成"在忙")
            let total = 0;
            for (let i = 1; i <= 8 && i < f.length; i++) total += parseInt(f[i]) || 0;
            const idle = (parseInt(f[4]) || 0) + (parseInt(f[5]) || 0);
            const busy = total - idle;
            next[key] = [busy, total];

            const p = prev[key];
            const ratio = (p && total > p[1]) ? (busy - p[0]) / (total - p[1]) : 0;
            if (key === "cpu") root.cpuUsage = Math.max(0, Math.min(1, ratio));
            else cores.push(Math.max(0, Math.min(1, ratio)));
        }

        root._cpuPrev = next;
        root.coreUsage = cores;
    }

    function readMem(text: string): void {
        let total = 0, avail = 0;
        for (const line of text.split("\n")) {
            if (line.startsWith("MemTotal:")) total = parseInt(line.split(/\s+/)[1]) || 0;
            else if (line.startsWith("MemAvailable:")) { avail = parseInt(line.split(/\s+/)[1]) || 0; break; }
        }
        if (total <= 0) return;
        root.memTotalGiB = total / 1048576;                       // kB → GiB
        root.memUsedGiB = (total - avail) / 1048576;
        root.memRatio = (total - avail) / total;
    }

    function readNet(text: string): void {
        let rx = 0, tx = 0;
        for (const line of text.split("\n")) {
            const colon = line.indexOf(":");
            if (colon < 0) continue;
            const name = line.slice(0, colon).trim();
            if (/^(lo|virbr|docker|veth|br-|tun|tap)/.test(name)) continue;
            const f = line.slice(colon + 1).trim().split(/\s+/);
            rx += parseInt(f[0]) || 0;
            tx += parseInt(f[8]) || 0;
        }

        const prev = root._netPrev;
        if (prev) {
            const secs = root.interval / 1000;
            root.netRx = Math.max(0, (rx - prev[0]) / secs);
            root.netTx = Math.max(0, (tx - prev[1]) / secs);
        }
        root._netPrev = [rx, tx];
    }

    // 单位跟 net-io.sh 一致:B / K / 一位小数的 M
    function fmtRate(bps: real): string {
        if (bps < 1024) return Math.round(bps) + "B";
        if (bps < 1048576) return Math.round(bps / 1024) + "K";
        return (bps / 1048576).toFixed(1) + "M";
    }
}
