# Quickshell 桌面组件

整个桌面只跑**一个** quickshell 实例（`qs`，不带 `-c`）。

| 文件 | 内容 | IPC target |
| --- | --- | --- |
| `shell.qml` | 入口。共用的聚焦显示器播种放在这里 | — |
| `osd/Osd.qml` | 音量 / 亮度 / 麦克风 OSD | `osd` |
| `osd/Notifications.qml` | 通知守护（替代 mako） | `notif` |
| `osd/Power.qml` | 电源菜单（替代 wlogout） | `power` |
| `osd/Track.qml` | 曲目切换 OSD | `track` |
| `bar/Bar.qml` | 状态栏（替代 waybar），每块屏一条 | — |
| `bar/Theme.qml` | 状态栏配色/字号/间距（全部来自 waybar 的 style.css） | — |
| `bar/BarItem.qml` | 模块外壳：内容 + 鼠标事件 + 悬浮浮层 | — |
| `bar/SysInfo.qml` | CPU / 内存 / 网络吞吐的采样（读 `/proc`） | — |
| `bar/Dev.qml` | 只跑状态栏的调试入口，栏放屏幕底部 | — |
| `screensaver/Screensaver.qml` | matrix 雨屏保（空闲 300s） | `saver` |
| `screensaver/MatrixRain.qml` | 雨的画面本体，不管什么时候该出现 | — |

`osd/` 放的是转瞬即逝的屏上覆盖层。`screensaver/` 是常驻但平时零成本的组件——不下雨时
整棵对象树都不存在（`LazyLoader`）。`bar/` 是常驻可见的状态栏，2026-08-27 从 waybar 迁过来。

调状态栏用 `qs -p config/quickshell/bar/Dev.qml` 起独立实例（栏放底部，可以和原 waybar
并排比对）；别直接热重载进主实例试错——主实例带着通知守护，一个语法错误会把通知、OSD、
屏保连同状态栏一起卸掉。

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
qs ipc call saver preview            # 立刻下雨,调样式时不用真坐等 300s
qs ipc call saver dismiss            # 收起
qs ipc call track preview            # 曲目 OSD,调样式时不用真去切歌
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

## 屏保

空闲 300s 铺满每块屏的 matrix 雨。**纯装饰**：不做认证、不替代锁屏，任意输入即退。

时间轴横跨两份配置，`hypr/hypridle.conf` 改了这边也要跟着改：

| 时刻 | 事件 | 配置在哪 |
| --- | --- | --- |
| 300s | 下雨 | `Screensaver.idleTimeout` |
| 880s | 停画，整棵对象树卸掉 | `Screensaver.stopTimeout` |
| 900s | `dpms off` | hypridle |
| 1800s | `loginctl lock-session` → hyprlock | hypridle |

880 这个数不是随便取的：hypridle 900s 直接关屏，再往黑屏上渲染纯属白烧 GPU，提前 20s 收工。

### 雨怎么画的

**整屏一个 `ShaderEffect`**（`matrix.frag`）。每个像素自己算落在哪个格子、那一格该多亮、
显示哪个字形；每列的速度 / 亮尾长度 / 明暗 / 相位由**列号 hash 出来**，不从 CPU 传任何
per-column 数据，CPU 每帧只更新一个 `time`。字形来自一张运行时生成的图集——半角片假名加数字排成一横条，`ShaderEffectSource` 烤成纹理，
再由 shader 以 nearest 放大成像素块（见坑 25）。

两条设计上的要点：

- **字符是钉在网格上不动的，动的只有亮度。** 这是 matrix 雨的本质，也是最容易做反的地方。
  直觉写法是"一条字符流整体向下平移"，但那样拖尾里的字符会跟着一起走，看着是一整块在滑动；
  对照 cmatrix——格子里的字符不动，是**亮点逐个把它们点亮、再让它们暗下去**。
- **相邻两列可以一起下雨，但亮尾要在垂直方向错开**（`headGap`）——并排没问题，一个在上
  一个在下就不难看。实现上有三个点，每一个都是踩出来的：
  - **判断锚在"这一趟开始的那一刻"，不是"此刻"。** 用此刻的话决定会在半途翻转：一列正
    下到一半、邻居一冲突它当场消失，冲突过去又当场出现在半屏中间——表现就是"闪一下就
    没了"和"凭空急速下滑"。锚住之后整趟共用一个决定。
  - **必须预判整趟，而不是只看开跑那一刻。** 两列速度不同，下落途中相对位置一路漂移；
    一趟好几秒、速度差能有十几格/秒，开跑时错开二十格的两条雨半途照样追平。所以沿整趟
    采样若干时刻，任何一刻会撞上就整趟不出。
  - 判断用邻居的**名义**位置（不管邻居自己是否也在让位），所以是纯函数、不会递归。
    代价是偶尔保守：邻居其实因为它自己的邻居没下雨，这一列也白让了一趟。
- **`overlapBelow` 是密度旋钮。** 尾梢暗到一定程度后压在一起根本看不出来，放它过去能换回
  成倍的密度。4K 横屏实测（"亮部"指绿色分量 >110 的那截）：

  | `overlapBelow` | 有雨的列 | 任意重叠 | **亮部**重叠 |
  | --- | --- | --- | --- |
  | 0（整条都不许重叠） | 11% | 0 | 0 |
  | **0.35**（当前） | **24%** | 6 对 | **0 对** |
  | 0.55 | 31% | 38 对 | 26 对 |

  0.35 是甜点：密度翻倍而亮的部分一次都没撞上；再松就开始出现真正难看的并排了。
- **点亮是硬边，熄灭是渐变。** 磷光体被电子束扫到才亮，所以亮点前方不发光；余晖只在后面，
  按幂次衰减。（试过让亮点前方"预热"渐亮，不像 CRT，已否掉。）
- **一格的字符在一整趟雨里是固定的**，亮着时绝不变；等这趟走完、亮尾归零、格子早看不见了，
  下一趟才换新的。别图省事按固定频率闪——那样亮着的字符会当着眼前变掉。种子取
  `hash(格子, 第几趟)`，"第几趟"是 `floor(t / cycle)`，天然满足这个约束。

改完 `matrix.frag` **必须重新编译**，QML 加载的是 `.qsb` 不是 `.frag`：

```bash
/usr/lib/qt6/bin/qsb --qt6 -o matrix.frag.qsb matrix.frag
```

`.qsb` 是编译产物但**必须入库**：`~/.config` 是软链过去的，没有安装步骤，运行时得能直接读到；
也不该要求每台机器都装 `qt6-shadertools`。

### 调参

全部在 `MatrixRain.qml` 顶部，按用途分了组。**改这些只要存盘**——QML 热重载，
不需要重新编译 shader（只有改 `matrix.frag` 才要，见上）。

| 想调什么 | 改哪个 | 说明 |
| --- | --- | --- |
| **密度（空间）** | `cellW` / `cellH` | 格子间距，调小 = 更多行列 = 更密。**不影响性能**（shader 逐像素，与格子多少无关），也不再牵连字号 |
| **列避让** | `headGap` | 相邻列的亮尾至少错开几行。0 = 不管 |
| **避让松紧** | `overlapBelow` | 亮度低于它的尾梢允许和邻居重叠。**这是密度旋钮**，见下表 |
| **荧光** | `glow` / `glowRadius` | 字形周围洇出来的一圈柔光。`glow: 0` 关掉 |
| **扫描线** | `scanline` | 老显示器的横向条纹。0 关，0.15~0.3 比较像，再大就闪 |
| **密度（时间）** | `gapMin` / `gapMax` | 一趟雨走完后空几格再开下一趟。`0` = 一趟接一趟（当前值），调大则列上出现空窗，整屏更稀 |
| **字号** | `fontScale` | 字占格子的比例，常用 0.8~0.95。**想让字更大又不想变稀，调这个而不是 `cellH`** |
| **字体** | `fontFamily` | 必须覆盖半角片假名，见下 |
| **像素感** | `glyphPixels` | 字形烤进图集的高度。调小 = 像素块更大更颗粒。**必须整除 `cellH`** |
| **日文比重** | `digitWeight` | 数字整组重复几次。45 个假名配 3 组数字 ≈ 6:4，嫌日文多就调大 |
| **硬边** | `sharpen` | 字形 alpha 的二值化阈值，消抗锯齿灰边。设 `0` 关掉（矢量字体想要平滑时） |
| **速度** | `minSpeed` / `maxSpeed` | 单位是**格/秒**，不是像素/秒 |
| **亮尾长度** | `minLen` / `maxLen` | 单位是格 |
| **亮度** | `dimMin` / `dimMax` | 每条流的整体明暗，层次靠它 |
| **颜色** | `color` / `headColor` | 雨的颜色 / 亮点的颜色 |

几点提醒：

- **"密度"有三个方向**，别混。`cellW`/`cellH` 决定屏幕上塞多少行列；`gapMin`/`gapMax` 决定
  同一列多久来一趟；`avoidAdjacent` 则会挤掉一部分（相邻冲突时奇数列让位）。
  开着避让时实测每帧有雨的列在 31%~40% 之间浮动——**想让整屏更满就加大 `gap`**：
  偶数列的空窗期变长，奇数列才有更多机会补进去。
- `cellW` 只改列间距，**不改字号**——字号只由 `cellH`/`glyphPixels` 那条链决定，
  `cellW` 变大只是把同样大的字形放进更宽的格子里居中。用偶数，否则图集单元宽会被四舍五入。
- **`minLen`/`maxLen` 的跨度要大。** 等长会让所有尾巴末端连成一条整齐的横线，一眼假。
  速度、明暗同理——随机性的任何一维退化成定值，出来的就是一层一层的横纹而不是雨。
- **`dimMin` 别调低。** 太低整屏发灰，观感上的"密度不够"多半是亮度问题不是列数问题。
- **换字体前先确认它覆盖你用到的字符**，否则整屏豆腐块——而且 fontconfig 会悄悄 fallback，
  不报任何错：

  ```bash
  fc-list ':charset=ff71' family | grep -i <字体名>    # 有输出才行
  ```

  注意 `:charset=` 要作为**查询条件**放在 pattern 位置。写成 `fc-list "某字体" :charset=ff71`
  是把它当成了要输出的字段，那样永远有输出，等于没查——这里踩过。
- 当前用的 `Maple Mono NF CN` **其实不覆盖片假名**，假名会 fallback 到 Noto Sans Mono CJK，
  也就是数字是 Maple、假名是 Noto 混着。这是挑字形观感时选定的，不是漏网之鱼；
  想让整套统一就换 `Noto Sans Mono CJK SC`。
- 字符集用**半角**片假名 U+FF71..FF9D。半角区天然只有清音——浊音在半角里要靠组合符号
  ﾞﾟ 拼，所以不像全角区 U+30A1..30F6 那样一取一整段就把 ゾ ヅ ボ ジ 和小写假名全带进来，
  点又多又碎、整屏看着脏。
- 改了 `cellW`/`cellH` 的**比例**不用管字形拉伸，图集单元格会自动跟着算。但 `cellH` 必须是
  `glyphPixels` 的**整数倍**，见坑 25。

### 其他

- **空闲检测用 `IdleMonitor`（ext-idle-notify-v1），和 hypridle 同一个协议**，不用自己数时间。
  它的 `respectInhibitors` 属性直接白送"看视频不弹屏保"——应用申请的 idle-inhibit 会被尊重。
- **层级选 `Overlay` 是为了盖住 waybar**。waybar 是 Top 层的 layer surface，kitty + cmatrix
  那种普通 toplevel 窗口压根盖不住它。要反过来让 waybar 露在雨上面，把 `WlrLayershell.layer`
  改成 `WlrLayer.Bottom`。
- 另一个 kitty + cmatrix 给不了的好处：**layer surface 不参与 dwindle 平铺**，屏保每隔几分钟
  弹一次也不会把布局搅乱（普通窗口会，见长期记忆 `hyprland-dwindle-silent-focus`）。
- **通知会浮在雨上面**（已实测）。同为 overlay 层时合成器按 surface 创建先后叠，而通知的
  surface 是收到通知那一刻才建的，永远比常驻的屏保晚。调 `shell.qml` 里的声明顺序没用。
- 排查"屏保怎么不出现"用 `qs ipc call saver state`：idle / forced / dismissed 三个状态位
  肉眼看不出来，它能直接区分"压根没触发"和"刚被一次输入收起了"。**自动化截图尤其要注意**——
  屏保会被任何输入收起，脚本跑到一半人动一下鼠标，拍到的就是桌面。

## 通知的按钮

非 `default` 的 action 会画成按钮（`default` 不画 —— 它是"点卡片"那一下）。

样式上按钮**不是卡片里浮着的独立方块**，而是把胶囊下半部分切出来：一条横线分隔内容区，
按钮之间用竖线分，于是它们读起来是胶囊的一部分而不是贴上去的。

两个实现要点：

- 悬停高亮必须按位置带上卡片的下角圆角（`bottomLeftRadius` / `bottomRightRadius`，
  Qt 6.7+ 才有），否则方角会捅出胶囊轮廓外。只有一个按钮时两个角都要带。
- **分隔线用黑色 alpha，不要用固定灰。** 卡片是半透明的，合成后约 rgb(213,213,215)，
  跟边框色 `#d2d2d7`(210,210,215) 几乎同色 —— 那样画出来根本看不见（踩过）。

## 与 mako 的关系

已完全替代，**mako 的包和配置都已删除**，没有回退路径了。

配色、位置、超时、免打扰规则当初是逐项照 `config/mako/config` 对齐的。那个文件已经不在，所以
`osd/Notifications.qml` 里那些 `// mako border-radius=12`、`// mako text-color` 之类的行尾注释
是这些数值的唯一出处记录 —— 改样式时它们就是基准，别顺手删掉。

## 状态栏（bar/）

2026-08-27 从 waybar 迁过来。外观是 1:1 复刻：`bar/Theme.qml` 里每个数值都标了对应
`config/waybar/style.css` 的哪条规则，`bar/Bar.qml` 里每个模块都标了对应 `config.jsonc`
的哪个 key。刻意**不**一样的只有两处（用户 2026-08-27 决定）：托盘可折叠成悬浮面板、
CPU/内存有悬浮详情面板——waybar 侧这两件事都得另起窗口，而这正是迁移的动机。

数据来源分三类：

- **quickshell 原生服务**：工作区（`Quickshell.Hyprland`）、托盘（`Services.SystemTray`
  + `DBusMenu`）、音量（`Services.Pipewire`）、电池与键盘电量（`Services.UPower`）、
  蓝牙（`Quickshell.Bluetooth`）、网络（`Quickshell.Networking`）、时钟（`SystemClock`）
- **自己读 `/proc`**：CPU / 内存 / 网络吞吐，见 `bar/SysInfo.qml`。这是整条栏里唯一
  没有现成服务的部分
- **沿用 waybar 时代的脚本**：`bar/scripts/{stock.sh,claude-usage.sh}`。它们各自管着缓存、
  鉴权、重试，没有理由用 QML 重写

通知模块从此是**进程内直连**：`shell.qml` 把 `Notifications` 实例传给 `Bar`，免打扰状态
和历史都是属性绑定。迁移前那条 `waybar → notifications.sh → qs ipc call notif →
pkill -RTMIN+1 waybar` 的回路连同脚本一起没了。

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

### 18. `Keys` 挂不上 `PanelWindow`

`PanelWindow` 不是 `Item`，直接在它里面写 `Keys.onPressed` 只会得到一句

```
Could not attach Keys property to: ...WaylandPanelInterface... is not an Item
```

**是 WARN 不是 ERROR**，面板照样独占键盘，只是没人处理按键——兜底静默失效。要在里面放个
`FocusScope { focus: true }` 再挂 `Keys`（`Power.qml` 和 `Screensaver.qml` 都是这么写的）。

### 19. 别在 `SequentialAnimation` 的 `ScriptAction` 里改这个动画组自己的属性

想让一条流循环"随机参数 → 下落 → 再随机"，很自然会写成
`SequentialAnimation { loops: Infinite; ScriptAction { script: 改 from/to/duration } ... }`。
结果是 `RangeError: Maximum call stack size exceeded`：改正在运行的动画组的子动画属性会让
Qt 把动画组重启，于是又回到 `ScriptAction`，同步递归到爆栈。

改成由 `NumberAnimation.onFinished` 驱动下一轮（改属性时动画一定是停的）。顺带一个独立的雷：
动画 `duration` 取整成 0 会让整条流一闪而过，算出来的时长要设下限。

### 20. 面板尺寸是**分步**就位的，`> 0` 的门控挡不住

`anchors.fill: parent` 异步生效，面板刚创建那一刻是 0x0，delegate 里任何"按屏幕高度算"的
初始化都会拿到 0。所以门控写在 model 上：

```qml
model: (rain.width > 0 && rain.height > 0) ? rain.cols : 0
```

**但这只挡得住第一步。**`height` 会先变成一个很小的非零值再跳到全屏，门控那一刻就放行了，
而 `rows = max(1, ceil(height / cellH))` 此时还是 1。屏保的表现是：首轮把流的终点算成
第 `1 + len` 行，于是流下到不到半屏就"走完"消失，且**只在刚亮的头几秒出现**。
更阴的是 `rows` 被 `max(1, …)` 兜着，从 0 到小值根本不触发 `rowsChanged`，加日志都看不见中间态。

可靠的做法是不信任"创建那一刻"的尺寸，而是尺寸一变就重置：

```qml
Connections {
    target: rain
    function onRowsChanged(): void { fall.stop(); col.first = true; col.cycle(); }
}
```

（`stop()` 不会发 `finished`，不用担心递归。）

现在的 shader 版天然免疫这个——`rows`/`cols` 只是 uniform，变了下一帧就生效，没有
"创建那一刻算好的 per-column 状态"。但凡是在 `Component.onCompleted` 里读尺寸的代码都要当心。

### 21. 空闲组件的"已取消"标志要挂在 idle **开始**，不能挂 resume

屏保被按键收起时，同一次按键既让合成器发 idle resume、又走面板的 `Keys` 兜底，两者顺序不定。
把"清除已取消标志"挂在 `isIdle` 转 false（resume）上，resume 先到就会被随后的 `dismiss()`
重新置位——标志从此卡死，屏保再也不出现，而且不报任何错。挂在 `isIdle` 转 **true**
（新一轮空闲开始）上就没有竞态。

### 22. QML 逐格更新画不动整屏动画——这是上 shader 的理由

屏保最初用 QML 实现"每个格子一个 `Text`，亮点扫过时改 `opacity`"，4K 双屏踩了三个坑，
每个都值一条经验，但合起来说明这条路本身有天花板：

1. **别把逐格属性绑定在"一直在动的量"上。** 把 `opacity` 绑定到亮点位置 `head`，
   亮点每跨一格就要重算整列 `rows` 个格子的绑定，全屏约 1.7M 次求值/秒，实测 8fps。
   绑定按"依赖变了就重算"工作，而你知道绝大多数格子的结果根本没变——改成主动更新窗口内
   那十几个格子，一步到 25fps+。
2. **增量更新必须扛得住"一次跳多步"。** 只熄灭 `head - len` 那一格是不够的：掉帧时
   `head` 一次跳好几格，中间被点亮过的格子就再没人熄灭。而且它**自我强化**——亮格子越积
   越多 → 渲染越慢 → 跳得更多，帧率从 27 一路衰减到 4 并伴随 400ms 尖峰。凡是"每次事件
   推进一步"的增量逻辑，都要先问：事件漏了或合并了会怎样。
3. **格子尺寸变成了帧率旋钮。** `Text` 总数 = `cols x rows`，压倒性地决定帧率：
   `14x19` 23fps、`18x24` 44~62fps、`20x27` 稳 62fps。想更密就得牺牲流畅。

即便三个都修好，稳态也只有 48~62fps 且**肉眼可见地忽快忽慢**——JS 执行、GC、Timer 调度的
抖动全看得见。换成 shader 后稳定 62.5fps，密度还免费。

测帧率用 `FrameAnimation`（Qt 6.4+），`PanelWindow` 没有 `frameSwapped` 可用：

```qml
FrameAnimation { id: fa; running: true }   // 1 / fa.smoothFrameTime 就是 FPS
```

这次三个性能问题全靠它定位——"观感卡"不变成数字，就只能瞎猜。

### 23. `ShaderEffect` 的 uniform 按名字匹配，对齐不用自己操心

QML 里声明的属性按**名字**对应 `matrix.frag` 里 uniform block 的成员——改名要两边一起改，
少写一个属性也不报错（那个 uniform 就是 0）。

布局虽然是 std140，但每个成员的 offset 由编译器算好写进 `.qsb` 的 reflection，Qt 照着绑，
所以**增删成员是安全的，不用手动数对齐**。想确认实际布局：

```bash
/usr/lib/qt6/bin/qsb --dump matrix.frag.qsb   # Reflection info 里有每个成员的 offset
```

另外 `fragColor` 要输出 premultiplied alpha（`vec4(rgb * a, a)`），Qt 期望的是这个。

### 24. 逐格的时间过渡，区间必须跨过一格以上

给格子做"渐亮"这类时间过渡时，过渡区间窄于一格是无效的：相邻格子到亮点的距离正好差 1，
区间窄于一格时同一时刻永远只有一格处在过渡中间，空间上看就是硬切；时间上也只持续
（区间宽 / 速度）秒——0.9 格配 18~58 格/秒只有 15~50ms，等于没有。

验证这种"只在时间维度可见"的效果，别靠肉眼看截图：用 PIL 沿亮尾取一条**垂直亮度剖面**，
逐格打印数值，是阶跃还是渐变一目了然。

### 25. 「像素化但清晰」，三个条件缺一不可

屏保的像素感不依赖点阵字体——机制是**低分辨率烘焙 + nearest 放大 + 二值化**，任何字体都能
人工点阵化（`glyphPixels` 控制烘焙到多少行，`sharpen` 控制二值化阈值）。但要清晰，三件事缺一不可：

1. **`cellH` 必须是 `glyphPixels` 的整数倍。** 图集单元被 nearest 放大到格子大小，非整数倍时
   有的源像素占 2 个屏幕像素、有的占 3 个，像素块宽窄不匀——这就是"糊"的主因。
2. **`ShaderEffectSource { smooth: false }`。** 不关线性过滤，放大出来只是一张糊图。
3. **shader 里二值化**（`sharpen`）。字形烘焙时带抗锯齿灰边，放大后就是一圈毛边，
   `a = step(sharpen, a)` 一行解决。

另外 `Text` 要加 `renderType: Text.NativeRendering`——默认的 distance field 渲染会给字形
加抗锯齿，一糊就白用了。

想要**真**点阵字体：换 `Unifont`（`otf-unifont`，已在包清单里）并把 `glyphPixels` 设成 16
（它的原生点阵高度）。注意它半角只有 8x16——宽度只有 8 个点，笔画稍多的假名会挤成一团；
全角是 16x16，但那要求格子也是正方形，同样宽度只能塞一半的列。

判断像素化到底行不行，别靠肉眼看全屏截图：裁一小块用 **NEAREST 放大**看，
像素块是不是方的、边是不是硬的，一眼就知道。

```python
Image.open("shot.png").crop((1500,400,1800,740)).resize((900,1020), Image.NEAREST).save("zoom.png")
```

### 26. 整数索引 ÷ 步长再取整，先挪到格子中心

早先的列稀疏实现要把列号 `c` 分槽：`slot = floor(c / stride)`。这行在 `stride` 取 2 或 4 时
完全正常，取 3 就有大片本该有雨的列全空——因为 `c` 是整数、**正好落在槽边界上**，而 `c/3`
在浮点里有舍入误差，往下掉一点点 `c=3` 就被算进了 slot 0，那个槽于是没有任何列匹配。
2 和 4 是 2 的幂、除法精确，所以看不出问题。

```glsl
float slot = floor((c + 0.5) / stride);   // +0.5 挪到格子中心，对任何步长都稳
```

那版实现后来被 `avoidAdjacent` 换掉了（语义不同，见上），但这个坑本身是通用的：凡是
"整数索引 ÷ 步长再取整"都会撞上，而且**只在特定步长下暴露**，很容易漏测。
验证要覆盖非 2 的幂。

顺带一个排查手法：这类"分组/判定"的 bug，光看渲染结果分不清"判定错了"还是"判定对了但
恰好不可见"。往 shader 里塞一行 `fragColor = vec4(0,0.25,0,0.25); return;` 让判定通过的
列整列涂色，直接数出来，一次就定位了。


### 27. Hyprland 的 IPC 请求不能并发发，别手动 refresh

`Hyprland.monitors` 恒为 0、`workspace.id` 恒为 -1、`lastIpcObject` 恒为 undefined ——
看起来像"这些属性在这个版本不可用"，其实是**并发请求把彼此的响应冲掉了**。

quickshell 在首次访问这些属性时会自己发一轮 `j/status` + `j/monitors` + `j/workspaces`
+ `j/clients`，这一轮是排好序的、正常。如果你另外再手动调一次
`Hyprland.refreshMonitors()` / `refreshWorkspaces()`，两轮撞在一起，解析出来就是空的
（日志里照样打印 "parsing monitors response"，**不报错**）。

实测：错开 2 秒分别调没问题；连着调就废。**结论是根本不用调** —— 只读属性，
quickshell 自己那一轮加上事件流就是全的。

排查手法：`qs -p x.qml --log-rules 'quickshell.hyprland.ipc=true' --log-times`
能看到请求与解析的时序；同时用 `printf 'j/workspaces' | socat - UNIX-CONNECT:$sock`
直接问 Hyprland，确认不是它那边返回的问题。

### 28. `font.families` 在这里不存在，图标必须单独一个 Text

CSS 的 `font-family: A, B, C` fallback 链在 Qt 里对应 `font.families`，但 quickshell 的
QML 引擎里**这个属性根本不存在**（Qt 6.11 实测，连字面量数组都报
`Cannot assign to non-existent property "families"`）。只能用 `font.family` 指定单个字体。

于是缺字只能靠 fontconfig 回退，而 **Nerd Font 的图标在私有区，私有区的回退不可靠**。
所以图标和文本要**拆成两个 Text**：图标那段显式 `font.family: Theme.iconFont`。

有意思的是混排字符串（`"󰍛 25%"`）反而能显示——那些是 plane 15 的码位，fontconfig
认得。真正会掉的是 BMP 私有区，见下一条。

### 29. BMP 私有区（U+E000–F8FF）的字符会在编辑链路里被吞掉

Arch 图标 U+F303、蓝牙 U+F294 这类直接写成字面量，写进文件后会变成**空字符串**
（表现为状态栏上一块空白，不报任何错）。而 `󰍛`（U+F035B）这种 plane 15 的四字节字符
不受影响——所以"有的图标好好的、有的没了"很容易看成字体问题。

一律写成 `\uXXXX` 转义，顺带还能 grep：

```qml
text: "\uf303"                       // nf-linux-archlinux
text: "\udb80\udcb1"                 // 󰂱 U+F00B1,四字节的要写成代理对
```

自检：`python3 -c "print([hex(ord(c)) for c in open(f).read() if 0xE000<=ord(c)<=0xF8FF])"`

### 30. waybar 的 `#workspaces button { color: @muted }` 从来没生效过

复刻工作区配色时照着 CSS 直译会得到"非活动工作区是灰的"，但**实际 waybar 渲染出来是
前景色 #f5f5f7**（截图取色实测 (245,245,247)）。

原因是 GTK 的选择器落在不同控件上：`#workspaces button` 命中按钮本身，而按钮里还有个
label 子控件，被顶部的 `* { color: @foreground }` 直接命中。两条规则作用对象不同，
label 自己的那条赢了。同理 `button:hover { color: @foreground }` 也是空转。

`.empty` 的 `opacity: 0.5` 作用在整个按钮上，所以空工作区是**前景色压 0.5**而不是
muted 压 0.5（实测 (137,141,145)，muted 压 0.5 会是 (90,93,96)）。

教训：从 CSS 迁到 QML 时，**以截图取色为准，不要以 CSS 文本为准**。

### 31. 状态栏要每块屏都建，不能照抄通知那条 filter

`osd/Notifications.qml` 用的是 `Quickshell.screens.filter(s => s.name === activeMonitor)`
（坑 7：只给活动屏建面板，省掉隐藏屏上整列 delegate 的实例化和图片解码）。**状态栏不能
这么写** —— 会变成只有焦点屏有栏，切屏时另一块屏的栏凭空消失。

相应地，栏里一切"当前"语义都要按**本面板这块屏**算。`HyprlandWorkspace.active` 的语义是
"在它自己那块屏上活动"，双屏时两块屏的当前工作区**同时**为 true，直接拿它点高亮会两块
屏各点亮两个。要再比一次 `w.monitor.name === panel.modelData.name`。

不依赖截图的验证方式（锁屏时也能查）：

```bash
hyprctl layers -j | jq -r 'to_entries[]|.key as $m|.value.levels|to_entries[]|.value[]?|select(.namespace=="quickshell-bar")|"\($m) \(.w)x\(.h) @\(.x),\(.y)"'
```

### 32. 浮层要设 `FlipY`，否则"看起来根本没弹出来"

`PopupWindow` 锚在 `Edges.Bottom` 时，如果状态栏在屏幕**底部**（`Dev.qml` 就是这么调的），
浮层会被放到屏幕外，表现和"悬浮逻辑没生效"一模一样，很容易往错的方向查。

```qml
anchor.adjustment: PopupAdjustment.FlipY | PopupAdjustment.SlideX
```

`FlipY` 让合成器自己翻到上方，`SlideX` 管贴近屏幕左右边缘的模块（时钟、通知铃铛）。

另外**别给浮层里的每一项再套一层 PopupWindow**（比如托盘展开面板里逐个图标的 tooltip）：
浮层套浮层在 Wayland 上定位和层级都不好收拾。托盘面板的做法是在面板底部留一行显示
当前悬停项的名字，全程只有一个窗口。

### 33. `Text` 默认渲染有彩色边缘，状态栏要用 `NativeRendering`

Qt Quick 默认的 `Text.QtRendering` 在这块屏（scale 1.5）上渲染出来带明显彩色条纹，
字形也比 GTK 细一圈，和 waybar 并排能一眼看出不是一套东西。

```qml
renderType: Text.NativeRendering
font.hintingPreference: Font.PreferVerticalHinting     // = Theme.hinting
```

`NativeRendering` 治彩边。hinting 那项**必须是 `PreferVerticalHinting`**——它对应 fontconfig
的 `hintslight`，也就是 GTK 走的那条：

```bash
fc-match --verbose "Noto Sans" | grep hintstyle    # hintstyle: 1 = FC_HINT_SLIGHT
```

用 `PreferFullHinting` 会把**数字**的 cap height 从 18px 往下 snap 成 17px，而**字母不受影响**
（实测：字母段墨量 583 vs 579 完全一致，数字段却矮一像素）。表现就是"数字看着矮一点"，
很难指认到 hinting 上去。

诊断要点，按顺序：

1. **先量 advance 宽度**。宽度一样就说明字号没问题，差别在光栅化；宽度不一样才是字号。
   直接去调字号会把已经对上的宽度弄坏。
2. **数字和字母分开量**。这次就是只有数字对不上，混在一起量永远看不出规律。
3. **墨量要用覆盖总和，不要用阈值计数**。阈值计数会把"AA 分布不同"读成"字重不同"：
   同一串文字，阈值法说 waybar 多 10% 墨，覆盖总和法说只差 1.2%（真相是后者）。
4. 拿 FreeType 独立渲染做第三方基准，判断是哪一边偏了：
   `ImageFont.truetype(path, em)` 画一串再 `getbbox()`。

另外 `GDK_SCALE=2`（本仓库 env.lua 里设着）会让 GTK 应用按 2x 出图再由合成器缩到 1.5x，
waybar 的字因此比原生渲染略重一点。这条解释了残留的观感差异，但不是缺陷，也不用去追。

### 34. waybar 的 layer surface 是 31 逻辑像素高，不是 config 里写的 28

`config.jsonc` 的 `"height": 28` 是 GTK 控件高度，`style.css` 又给 `window#waybar` 加了
1px 边框，实测 `hyprctl layers` 报的是 **31**。照着 28 写会矮一截，独占区也跟着少 3px，
窗口布局比迁移前高一点点——肉眼很难发现，但一比几何就出来了。

迁移完的对照（waybar 停掉前后各查一次，位置和尺寸应当完全一致）：

```
DP-1       waybar 2544x31 @8,479   →  quickshell-bar 2544x31 @8,479
HDMI-A-1   waybar 1472x31 @2568,4  →  quickshell-bar 1424x31 @2568,4
```

竖屏那块 waybar 的 1472 比逻辑屏宽（1440）还宽 32px，是 waybar 在旋转输出 + 分数缩放下
的老毛病；quickshell 的 1424 = 1440 - 8 - 8 才是对的。

### 35. 中间模块不能用 `anchors.centerIn`，窄屏会压到右侧模块上

竖屏那块只有 1440 逻辑宽，左右两组占掉的宽度超过一半，硬居中的中间模块（股价）会直接
压在 cpu/内存上，文字叠文字。

waybar 用的是 GTK CenterBox：**放得下就居中，放不下就退化成顺序排布**（实测它甚至会把
arch 图标整个挤掉）。复刻前半段就够了——把居中位置夹在左右两组之间：

```qml
x: Math.max(leftEnd, Math.min((parent.width - width) / 2, rightStart - width))
maxWidth: Math.max(0, rightStart - leftEnd)      // 真挤不下就自己截断，绝不重叠
```

**只在窄屏上暴露**，主屏（2560 逻辑宽）怎么看都是好的——多屏配置里这类 bug 很容易漏测。

### 36. 托盘图标要 `QT_QPA_PLATFORMTHEME=gtk3`，否则是洋红方格

托盘图标里凡是走 `image://icon/<name>`（图标主题查找）的，不设这个变量就全部渲染成
洋红/黑方格占位。**只有恰好装进 `hicolor` 的应用（KeePassXC）能显示**，主题里的
（fcitx 的 `input-keyboard-symbolic`）一律失败。

原因是 **Qt 不读 `gtk-icon-theme-name`**。本机图标主题是 kora-green，配在
`~/.config/gtk-{3,4}.0/settings.ini` 里，Qt 看不到，退回默认只认 hicolor。

一行验证，不用截图：

```qml
Quickshell.iconPath("input-keyboard-symbolic", true)
// 默认环境          → ""
// QT_QPA_PLATFORMTHEME=gtk3 → "image://icon/input-keyboard-symbolic"
```

插件是 `libqgtk3.so`（qt6 自带）。设在 `autostart.lua` 里只给 `qs`，没写进 `env.lua` ——
全局设会让所有 Qt 应用都跟着 GTK 主题走，那是另一件事。

**注意这个变量热重载拿不到**，必须重启 qs 进程才生效（这是少数几个真要重启的场合之一）。

另外 `Image.status` 在这里**不可信**：图标没找到时它照样是 `Ready`，只是内容是占位图。
判断要看 `Quickshell.iconPath()` 的返回值，或者直接截图看像素。


### 37. `Rectangle.border` 画在填充之外，会把 1px 边框合成到**壁纸**上

用户报的现象是"字体高度没居中，而且整条 bar 更矮"。根因跟字体无关：

```
qs      y5:73 | y6:86 y7:86 | y8..50:38 | y51:87 y52:86 | y53:74
waybar  y64:73 | y65:52 y66:45 | y67..108:38 | y109:46 y110:53 | y111:76
```

栏体上下各多了一条亮度 86 的亮线。Qt 的 `Rectangle.border` 是**画在填充之外**的——那一圈
1px 里没有背景色，`#12ffffff`（白 7%）直接压在壁纸上：`72 × 0.93 + 255 × 0.07 = 85`，
和实测的 86 对得上。GTK 的 border 默认 `background-clip: border-box`，背景铺到边框底下，
所以 waybar 那条是不显眼的 45~53。

后果不直观：深色栏体被两条亮线从 46px 削成 43px，**整条栏看着变矮**，里面的文字也从
上15/下7 变成上13/下5、**像是没居中**。两个症状都指向"字体不对"，但改字体一个都修不好。

改法是分两层画，让边框 composite 的对象是栏体而不是壁纸：

```qml
Rectangle { anchors.fill: parent; radius: r; color: bg }                       // 背景铺满
Rectangle { anchors.fill: parent; radius: r; color: "transparent"              // 边框叠上去
            border.color: b; border.width: 1 }
```

验证手法：**沿一列打亮度剖面**，别靠肉眼看边框。一条 47 个数的序列，边框、背景、壁纸
三段一目了然，还能直接算出 composite 的对象是谁。

### 38. imports 之前的注释里不能出现花括号

在 `shell.qml` 顶部注释里写了一句"要重新启用就放开 `Bar ' + '{' + ' notifications: notifications ' + '}' + '`"，
整个配置就加载不了了，报的是：

```
Failed to load configuration
  caused by @shell.qml[50:5]: Power is not a type
```

**报错完全指向错误的方向** —— `osd/` 一个字都没动，四个类型单独 `qs -p` 加载全都正常，
但只要走完整的 `shell.qml` 就全部 "not a type"，而且报哪一个取决于谁排在最前面
（删掉 `id:` 之后错误就从 Notifications 跳到 Power）。

根因是 quickshell 扫描配置时**不剥注释**：imports 之前的注释里只要出现左花括号，它就认为
根对象已经开始，后面的 `import "osd"` / `import "screensaver"` 全都收集不到，于是目录导入
带来的类型一个都不存在。日志里唯一的线索是这一行：

```
Got intercept for "…/osd/qmldir" contains ""      # 生成出来的 qmldir 是空的
```

**同样的花括号写在对象体内部的注释里没事**，位置决定。定位手法：逐行删注释二分。
一开始我以为是注释里的 `import "bar"` 字样，替换掉之后照样失败 —— 真正的触发字符是花括号。

（顺带一个 shell 坑：用 `python3 -c "…"` 做替换时，zsh 会把双引号里的反引号当命令替换吃掉，
导致"我明明替换了却没生效"，白白排除掉一个正确的怀疑对象。这类替换要用 heredoc。）
---

改配置的工作流（热重载、不要重启进程、怎么验证）见仓库根目录 `CLAUDE.md`。
