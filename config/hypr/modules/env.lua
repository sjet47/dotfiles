-- 环境变量
-- 文档: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "28")
hl.env("HYPRCURSOR_SIZE", "28")

-- XWayland HiDPI: 以 2x 渲染再由 compositor 降采样到 1.5x 逻辑尺寸,接近 macOS HiDPI 效果
-- 配合 looknfeel.lua 里的 xwayland.force_zero_scaling = true
hl.env("GDK_SCALE", "2")
hl.env("QT_SCALE_FACTOR", "1.5")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "0")
hl.env("_JAVA_OPTIONS", "-Dsun.java2d.uiScale=2")

-- 输入法 (fcitx5)
-- hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("INPUT_METHOD", "fcitx")

hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/keyring/ssh")

hl.env("XDG_CONFIG_DIR", os.getenv("HOME") .. "/.config")
