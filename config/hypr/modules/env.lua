-- 环境变量
-- 文档: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_THEME", "Adwaita")  -- 原 breeze_cursors 随 plasma 一起删了
hl.env("XCURSOR_SIZE", "28")
hl.env("HYPRCURSOR_SIZE", "28")

-- XWayland HiDPI: 以 2x 渲染再由 compositor 降采样到 1.5x 逻辑尺寸,接近 macOS HiDPI 效果
-- 配合 looknfeel.lua 里的 xwayland.force_zero_scaling = true
hl.env("GDK_SCALE", "2")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "0")
-- QT_SCALE_FACTOR 刻意不在这里设。它不分后端、无脑相乘:原生 Wayland 的 Qt 应用
-- (vicinae / keepassxc / quickshell / binaryninja)会被它叠成 1.5x1.5=2.25 倍。
-- 全局设了就得给每个原生应用打 `env -u` 补丁,补漏一个就出错;所以反过来——
-- 全局不设,只给真正需要它的 XWayland 消费者单独设(见 autostart.lua 的 fcitx5)。
hl.env("_JAVA_OPTIONS", "-Dsun.java2d.uiScale=2")

-- 让所有 Electron 应用走 Wayland 原生(跟随显示器 scale,根治缩放问题)
-- 用 wayland 而非 auto:auto 让 Electron 自行检测,在 systemd scope(vicinae
-- 等 launcher 启动)这条路径上检测会失败回退 X11;wayland 强制、不检测。
-- 同样的值也写在 ~/.config/environment.d/(覆盖 systemd user service 路径)。
-- 边界:Google Chrome 非 Electron 不读此变量,仍靠 .desktop;输入法不受影响,
--       需中文输入的 Electron 应用仍各自带 --enable-wayland-ime。
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

-- 输入法 (fcitx5)
-- hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("INPUT_METHOD", "fcitx")

hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/keyring/ssh")

hl.env("XDG_CONFIG_DIR", os.getenv("HOME") .. "/.config")
