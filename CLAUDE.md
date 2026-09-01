# dotfiles

Arch Linux + Hyprland 的个人配置仓库。

## 视觉改动要截图自验证

改完 waybar 样式、Hyprland 外观（gaps/border/blur/动画）、wlogout 布局这类**视觉相关配置后，截图确认实际效果**，不要只凭代码判断对错：

```bash
~/.config/hypr/scripts/screenshot.sh fullscreen save   # 焦点显示器整屏
~/.config/hypr/scripts/screenshot.sh active save       # 当前活动窗口
```

两条都不需要交互，直接把 PNG 路径打到 stdout，Read 该路径即可查看图片。加了 `save` 就不会碰剪贴板、不弹通知，也不会打断用户手上正在进行的框选。

几点注意：

- waybar、通知卡片、OSD 都属于 layer-shell surface，不是窗口，只有 `fullscreen` 能截到。
- `active` 截的是当前焦点窗口——从终端里调用时焦点多半在终端上，先确认目标窗口真的处于焦点。
- 不带 `save` 的调用（`screenshot.sh`、`region`、`window`）是给人用的交互流程：会拉起框选、写剪贴板、弹标注通知，不要在自动化里用。

## Quickshell 配置改完不要重启进程

`config/quickshell/`（OSD + 通知守护，单实例 `qs`）**会自动热重载**：改完文件存盘，QML 立刻重新加载，直接看结果即可。

不要 `kill` 之后再 `qs &` 重来 —— 那样容易在旧实例还没退干净时起第二个，抢不到 `org.freedesktop.Notifications` 的那个只会白占内存。


几点注意：

- **不要用 `sed -i` 改这些文件。** 它是新建临时文件再改名覆盖，inode 一换 quickshell 的
  文件监视就失效，**之后无论怎么改都不再重载，而且不报任何错** —— 你会对着旧代码反复
  测试却毫无察觉（这里踩过，白测了好几轮）。用原地重写（Python `write_text`、编辑器保存）。
  已经用 `sed -i` 改过的话，只能重启 `qs` 才能恢复监视。

  **发现"改了不生效"时，先怀疑这一条，别急着归咎于别的机制。** 这里栽过一次：监视被
  `sed -i` 弄坏之后，因为往子目录文件里塞语法错误也不报错，就推断成"热重载够不到
  `import "screensaver"` 这类子目录模块"，还把这个假结论写进了本文件。重启恢复监视后
  复验：用 Python 原地重写子目录里的 `MatrixRain.qml`，改动**立刻生效** —— 子目录模块
  一直是能热重载的。判据很简单:**改入口 `shell.qml` 也不重载，那就是监视坏了，跟改哪个
  文件无关**。实测：

  | 写法 | inode | 是否重载 |
  | --- | --- | --- |
  | Python 原地重写 | 不变 | ✓ |
  | `sed -i` | **变** | ✗ |
  | `sed -i` 之后再用 Python | — | ✗ 仍然不重载 |

- 热重载**不重启进程**（PID 不变），`org.freedesktop.Notifications` 的 D-Bus 注册也保住，中途不会漏收通知。
- 但 QML 侧的运行时状态**全部重置**：正在显示的通知、免打扰开关、历史记录都会清空。要跨重载保留通知，得把 `NotificationServer.keepOnReload` 改成 `true`。
- 语法错误**不会杀掉进程，但会让整个 shell 卸载** —— 面板和 IPC 全没了（`qs ipc` 报
  `Not ready to accept queries yet`），期间通知也收不到。把文件改对后会自动恢复，PID 不变。
  所以改完顺手看一眼日志确认，别等到发现没通知了才回头找：

```bash
tail -5 "$(ls -t /run/user/1000/quickshell/by-id/*/log.qslog | head -1)"
```

- 验证动画类改动时，用 layer 几何精确取景，别靠肉眼估算坐标：

```bash
hyprctl layers -j | jq -r 'to_entries[]|.value.levels|to_entries[]|.value[]?|select(.namespace|test("quickshell"))|"\(.x) \(.y) \(.w) \(.h)"'
```

- 计时类测试会被飞书的告警污染（几十秒一条）。先 `qs ipc call notif dndToggle` 开免打扰隔离 —— 它只拦非 `notify-send`，自己发的测试通知照常通过。
