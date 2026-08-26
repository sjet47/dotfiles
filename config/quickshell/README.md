# Quickshell 桌面组件

整个桌面只跑**一个** quickshell 实例（`qs`，不带 `-c`）。

| 文件 | 内容 | IPC target |
| --- | --- | --- |
| `shell.qml` | 入口。共用的聚焦显示器播种放在这里 | — |
| `Osd.qml` | 音量 / 亮度 OSD | `osd` |
| `Notifications.qml` | 通知守护（替代 mako） | `notif` |

放在 `~/.config/quickshell/shell.qml` 就是 quickshell 的 "default" 配置 —— 注意此时**同目录下的子目录不会再被当成独立配置**。

## 对外接口

```bash
qs ipc call osd brightness <0-100>   # 亮度 OSD,由 hypr/scripts/brightness.sh 调用
qs ipc call notif dndToggle          # 切免打扰,返回 on/off
qs ipc call notif dndStatus
qs ipc call notif history            # 历史 JSON
qs ipc call notif invoke             # 触发最新一条的 default action(对应 makoctl invoke)
qs ipc call notif dismissAll         # 清空(对应 makoctl dismiss --all)
```

waybar 的 `custom/notifications` 模块经 `waybar/scripts/notifications.sh` 调用后三个。

音量不需要接口：直接监听 PipeWire，任何途径改音量都会弹。亮度没有便宜的读取方式（DDC 的 `getvcp` 一次 ~200ms），所以由 `brightness.sh` 维护缓存后推过来。

## 与 mako 的关系

已完全替代。mako 的包和 `config/mako/config` **仍保留**，只是 `systemctl --user mask` 掉了（原因见坑 1）。回退路径：

```bash
systemctl --user unmask mako.service
# 再把 hypr/modules/autostart.lua 里的 qs 那行换回 systemctl --user start mako.service
```

配色、位置、超时、免打扰规则都是逐项照 `config/mako/config` 对齐的，改样式时可以拿它当基准。

---

## 坑

### 1. mako 会被 D-Bus 激活抢回通知名

`/usr/share/dbus-1/services/fr.emersion.mako.service` 把 mako 注册成了 `org.freedesktop.Notifications` 的可激活提供者。只要这个名字空出来（quickshell 崩溃或重启的间隙），**任何一条通知都会把 mako 拉起来**，之后 quickshell 再也注册不上，日志里是：

```
Could not register notification server at org.freedesktop.Notifications,
presumably because one is already registered.
```

所以 mako 必须 mask。产生的 `/dev/null` 软链在 `config/systemd/user/mako.service`，已入库。

### 2. Qt 的八位色是 AARRGGBB，不是 RRGGBBAA

mako 写 `#f5f5f7d9`（RGB + alpha），照抄到 QML 会被读成 `alpha=0xf5, rgb=(245,247,217)` —— 一个 96% 不透明的**米黄色**。正确写法是 `#d9f5f5f7`。

### 3. QT_SCALE_FACTOR 会和显示器 scale 叠乘

quickshell 是原生 Wayland 的 Qt6 应用。`QT_SCALE_FACTOR` 不分后端、无脑相乘，320x64 的面板会变成 480x96。本仓库已把它从 `env.lua` 全局移除、只给 fcitx5 单独设，详见长期记忆 `qt-app-scaling-hyprland`。

### 4. OSD 用 `ExclusionMode.Ignore`，通知必须用 `Normal`

OSD 悬浮在底部中间，不该参与独占区计算。通知在右上角，用 Ignore 会**无视 waybar 的独占区**压到状态栏上（实测 y=495 落在 waybar 的 479..510 内，mako 是 530）。

### 5. 不要动画 layer surface 的尺寸

把 `implicitHeight` 绑定内容高度再加 `Behavior`，等于**每帧 resize Wayland surface**，缓冲区尺寸与内容重绘不同步，动画时会看到旧位置内容的残影。

做法是把面板**固定成整屏高**、内容在里面自由动，再用 `mask: Region { item: stack }` 把透明区域的输入放行 —— 否则这块看不见的覆盖层会吃掉下面窗口的点击（指针穿透已实测通过）。

### 6. JS 数组直接喂 Repeater 会整列重建

数组一重新赋值，`Repeater` 销毁并重建**所有** delegate，表现为其余卡片的图片闪一下重新解码。用 `ScriptModel { values: ... }` 做增量 diff，存活的 delegate 不动。

### 7. `Variants` 对所有屏建面板 = 每条 delegate 创建两次

靠 `visible` 控制显示的话，隐藏的那块屏照样实例化整列 delegate 并解码一遍图片（插桩实测）。改成只给活动屏建：

```qml
Variants { model: Quickshell.screens.filter(s => s.name === notif.activeMonitor) }
```

### 8. 退场动画必须延后真正的移除

从 model 里摘掉的瞬间 delegate 就销毁了，根本没机会播动画。所以 delegate 只负责播动画，真正的 `drop()` 放在 `onFinished` 里；而且收尾函数要写在 **Scope 上而不是 delegate 里** —— 让一个对象在自己的方法执行到一半时把自己销毁掉不安全。

`IpcHandler` 够不到 delegate，所以用 Scope 上的 `closeRequested(target, act)` 信号让卡片自己认领，这样 IPC 和鼠标走同一条动画路径。

### 9. 新卡片的进场不能靠 Column 的 `add:` 过渡

新通知插在 index 0，它的 y 本来就是 0，`add:` 是空转 —— 结果是它满不透明地立刻出现在顶部，而旧卡片还在 220ms 的下移过程中，两者重叠。参考 macOS，进场由 delegate 自己从屏外右侧滑入，与 `move:` 的下移并行。

### 10. 退场滑出会被面板边界裁剪

面板若在屏幕右侧留了 margin，卡片向右滑出时会在**屏幕内部**被裁出一条竖线。让面板贴屏幕边缘、把间距挪进面板内部由内容宽度承担，裁剪线就与屏幕边缘重合，看起来是正常滑出屏外。

### 11. 必须处理 `Notification.closed`

只处理自己的 expire/dismiss 是不够的。发送方主动 `CloseNotification` 或用 `replaces_id` 顶掉旧通知时对象会失效，而失效引用留在数组里会渲染成一张**永不消失的空白卡片**（它的 Timer 也绑在已失效的对象上，不再触发）。飞书的告警反复发，能堆出好几张。

```qml
n.closed.connect(function () { notif.drop(n); });
```

### 12. `Text.StyledText` 会把换行折叠成空格

通知 body 里是真换行符（`0a`，xxd 实测），但 StyledText 是 HTML 语义。要转成 `<br/>`。

排查时**别用 `jq @json` 判断**：它把真换行也显示成 `\n`，看不出是字面反斜杠还是真换行。用 `xxd`。

### 13. 通知图片要限制解码尺寸

截图通知传的是整张 4K PNG，不加 `sourceSize` 就按原分辨率解进内存，而每次截图都会发一条。

### 14. `Hyprland.focusedMonitor` 启动时是 null

它只在收到 `focusedmon` 事件时才赋值，实测启动 3 秒后仍是 undefined。启动时用 `hyprctl monitors -j` 播种一次，之后交给事件流。这段在 `shell.qml` 里，两个组件共用。

### 15. 内存代价

单实例约 **200MB** 起步，重度用图后收敛在 ~370MB（增长有界，不是泄漏）。对照 mako ~10MB。这是 Qt runtime + QML + GPU scene graph 的固定成本，评估要不要把更多组件迁过来时要算进去。

---

改配置的工作流（热重载、不要重启进程、怎么验证）见仓库根目录 `CLAUDE.md`。
