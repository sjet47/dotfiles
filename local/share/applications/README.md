# 用户级 .desktop 覆盖

这里放**手动改过启动参数**的 desktop entry，由 `init/steps/1-layout.sh` 的
`link_desktop_entries` 逐文件软链到 `~/.local/share/applications/`。

## 为什么不整目录 symlink

`~/.local/share/applications/` 里混着大量自动生成的条目——Steam 游戏、
Chrome PWA(`chrome-*-Default.desktop`)、`wine/`、`mimeinfo.cache`、
Thunderbird 的 `userapp-*`——整目录链接会把这些一起拖进仓库。

## 收录标准

只收「我们为了修显示/后端问题手工加了 flag」的：

| 文件 | 改了什么 |
|---|---|
| `com.anthropic.Claude.desktop` | Wayland + IME + `--password-store=gnome-libsecret`(keyring) |
| `obsidian.desktop` | Wayland + IME |
| `binaryninja.desktop` | `QT_QPA_PLATFORM=wayland` + `env -u QT_SCALE_FACTOR`(详见文件内注释) |
| `craft-agents.desktop` | Wayland(AppImage) |
| `lodyDesktop.desktop` | Wayland + IME |
| `stably-orca.desktop` | Wayland + IME |

不收的：没加自定义 flag 的手动条目(typora)、应用自己写入的 URL handler
(`cc-switch-handler`、`claude-code-url-handler`,重装会自动重建)、
`google-chrome.desktop`(8.5K 里只有 3 行 Exec 是我们的，其余全是官方翻译，
整份入库会随 Chrome 升级漂移，改成手动维护)。

## 背景

Electron/Qt 应用回退 XWayland 会因为 `xwayland.force_zero_scaling=true` +
显示器 scale 1.5 而糊掉/变小。环境变量 hint(`ELECTRON_OZONE_PLATFORM_HINT`)
不可靠，必须用命令行 flag。有 wrapper 会读 `*-flags.conf` 的应用(VSCode、飞书)
走 `config/code-flags.conf` / `config/feishu-flags.conf`；没有 wrapper 的
(raw Electron 二进制、AppImage)只能靠这里的 `.desktop` 覆盖。

覆盖要生效，**文件名必须与 `/usr/share/applications/` 里的系统版完全一致**
(XDG 按 desktop-file-ID 去重)，否则会变成 launcher 里的重复条目。

Electron 单例锁：改完 flag 要 `pkill -9` 彻底退出旧进程再开，否则新进程会把
窗口交还给无 flag 的旧 main 进程。
