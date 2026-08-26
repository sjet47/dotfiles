# Quickshell 桌面组件

整个桌面只跑**一个** quickshell 实例（`qs`，不带 `-c`）。

| 文件 | 内容 | IPC target |
| --- | --- | --- |
| `shell.qml` | 入口。共用的聚焦显示器播种放在这里 | — |
| `osd/Osd.qml` | 音量 / 亮度 / 麦克风 OSD | `osd` |
| `osd/Notifications.qml` | 通知守护（替代 mako） | `notif` |
| `osd/Power.qml` | 电源菜单（替代 wlogout） | `power` |

`osd/` 放的是转瞬即逝的屏上覆盖层。将来做常驻组件（比如 waybar 的替代）另开目录。

放在 `~/.config/quickshell/shell.qml` 就是 quickshell 的 "default" 配置 —— 此时**子目录不会再被
当成独立配置**，但那只影响"配置发现"，不影响 QML 自己的目录导入：`shell.qml` 里一句
`import "osd"` 就能把里面的组件按文件名当类型用，`required property` 照常传。

## 对外接口

```bash
qs ipc call osd brightness <0-100>   # 亮度 OSD,由 hypr/scripts/brightness.sh 调用
qs ipc call notif dndToggle          # 切免打扰,返回 on/off
qs ipc call notif dndStatus
qs ipc call notif history            # 历史 JSON
qs ipc call notif invoke             # 触发最新一条的 default action(对应 makoctl invoke)
qs ipc call notif dismissAll         # 清空(对应 makoctl dismiss --all)
qs ipc call power toggle             # 电源菜单,绑在 SUPER + ALT + M
qs ipc call power open / hide
```

waybar 的 `custom/notifications` 模块经 `waybar/scripts/notifications.sh` 调用后三个。

音量和麦克风不需要接口：直接监听 PipeWire。音量听 `defaultAudioSink` 的 volume/muted，
任何途径改音量都会弹；麦克风听 `defaultAudioSource` 的 **muted 而已** —— 音量变化可能来自
应用自动增益之类的后台行为，跟着弹会很吵，而 `XF86AudioMicMute` 绑的本来就是 set-mute。

亮度没有便宜的读取方式（DDC 的 `getvcp` 一次 ~200ms），所以由 `brightness.sh` 维护缓存后推过来。

## 电源菜单

5 个动作：锁屏 / 注销 / 挂起 / 重启 / 关机，字母快捷键 `l e u r s` 沿用 wlogout 默认，
方向键 + Enter 也可以，Esc 取消。相对 wlogout 的默认布局改了两处：

- **去掉 Hibernate**。本机有 64G swap 但没配 resume（`/sys/power/resume = 0:0`，
  内核参数里也没有 `resume=`），按下去会写盘关机却无法恢复，等于丢会话。
  以后要恢复这个按钮，得先在 refind 里补 `resume=` 再验证。
- **Logout 用 `hyprctl dispatch exit`**，不是 wlogout 默认的 `loginctl terminate-user`。
  会话由 `start-hyprland` 拉起、不归 uwsm 管（`wayland-wm@hyprland.service` 是 inactive），
  让合成器自己退出比杀掉整个 user 干净。

Lock 保持 `loginctl lock-session`：走标准会话锁语义，由 hypridle 的 `lock_cmd` 拉起 hyprlock。

## 与 mako 的关系

已完全替代，**mako 的包和配置都已删除**，没有回退路径了。

配色、位置、超时、免打扰规则当初是逐项照 `config/mako/config` 对齐的。那个文件已经不在，所以
`osd/Notifications.qml` 里那些 `// mako border-radius=12`、`// mako text-color` 之类的行尾注释
是这些数值的唯一出处记录 —— 改样式时它们就是基准，别顺手删掉。

---

## 坑

### 1. 别让第二个通知守护装进来

通知守护通常会装一个 D-Bus 激活文件（mako 当初是 `/usr/share/dbus-1/services/fr.emersion.mako.service`），
把自己注册成 `org.freedesktop.Notifications` 的可激活提供者。只要这个名字空出来
（quickshell 崩溃或重启的间隙），**任何一条通知都会把它拉起来**，之后 quickshell 再也注册不上：

```
Could not register notification server at org.freedesktop.Notifications,
presumably because one is already registered.
```

当时是靠 `systemctl --user mask` 压住的，现在 mako 已卸载所以没有这个问题。
但**如果以后又装了别的通知守护**（dunst / swaync / fnott …），同样的抢名会再来一次，
届时要么卸掉它、要么 mask 它的 service。

quickshell 自己**没有**激活文件，只能靠 autostart 抢先占名 —— 所以它挂掉时不会有人接管，
`notify-send` 会直接失败而不是静默换人。

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

它只在收到 `focusedmon` 事件时才赋值，实测启动 3 秒后仍是 undefined。启动时用 `hyprctl monitors -j` 播种一次，之后交给事件流。这段在 `shell.qml` 里，三个组件共用。

### 15. IPC 函数不能叫 `show`

`qs ipc` 自己有 `show` 子命令，所以 `qs ipc call <target> show` 会被解析成 introspection、
打印函数列表，**函数本身根本调不到**，而且不报错。电源菜单那个改名成了 `open`。
`hide` / `toggle` 之类没有冲突。

### 16. 要吃键盘的面板得设 `keyboardFocus`

OSD 和通知都是 `WlrKeyboardFocus.None`（默认），电源菜单需要 Esc / 方向键 / 字母快捷键，
所以设成 `Exclusive`。**它会独占键盘** —— 万一 Esc 分支写错，人就被锁在菜单里了，
所以 Esc 一定要放在 `Keys.onPressed` 的第一个分支。

验证键盘可以用 `wtype`（它注入的按键不触发 Hyprland keybind，但能进有焦点的 layer surface）。
测字母快捷键时别直接按 `r` / `s` —— 把 `execDetached` 临时换成 `console.log` 打索引再逐个试，
顺带能验证字母到动作的映射没串位。注意 `strings` 会过滤掉中文，日志里只打 ASCII。

### 17. 内存代价

单实例约 **200MB** 起步，重度用图后收敛在 ~370MB（增长有界，不是泄漏）。对照 mako ~10MB。这是 Qt runtime + QML + GPU scene graph 的固定成本，评估要不要把更多组件迁过来时要算进去。

---

改配置的工作流（热重载、不要重启进程、怎么验证）见仓库根目录 `CLAUDE.md`。
