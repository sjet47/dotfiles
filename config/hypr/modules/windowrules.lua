-- 窗口规则
-- 文档: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--
-- 排查窗口属性: hyprctl clients -j | jq '.[] | {class,title,initialClass,xwayland}'
-- 注意: name 是规则的唯一标识,重名会互相覆盖。
-- 注意: float 是静态效果,仅在窗口创建时判定一次,改规则后需重开窗口。

-- 忽略所有应用的最大化请求
hl.window_rule({
  name           = "suppress-maximize-events",
  match          = { class = ".*" },
  suppress_event = "maximize",
})

-- 修复 XWayland floating 窗口的拖拽问题
hl.window_rule({
  name = "fix-xwayland-drags",
  match = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },
  no_focus = true,
})

----------------------------------------------------------------------
-- 浮动窗口规则
----------------------------------------------------------------------

hl.window_rule({
  name      = "float-dropdowns",
  match     = { class = "dropdown" },
  float     = true,
  size      = "80% 40%",
  move      = "10% 0%",
  animation = "slide top",
})

hl.window_rule({
  name  = "move-hyprland-run",
  match = { class = "hyprland-run" },
  float = true,
  move  = "20 monitor_h-120",
})

hl.window_rule({ name = "float-satty", match = { class = "com.gabm.satty" },  float = true })
hl.window_rule({ name = "float-ksnip", match = { class = "org.ksnip.ksnip" }, float = true })

-- KeePassXC 数据库解锁/打开窗口,避免启动时占用 tiling 布局
hl.window_rule({
  name  = "float-keepassxc-database",
  match = { class = "(org.keepassxc.)?KeePassXC", title = ".* - KeePassXC$" },
  float = true,
})

-- XDG portal 弹窗(文件选择/屏幕共享授权等)
hl.window_rule({
  name  = "float-xdg-portal",
  match = { class = "^xdg-desktop-portal-(gtk|kde|hyprland)$" },
  float = true,
})

-- 飞书:图片预览(XWayland,class 为空,title 固定"图片")
hl.window_rule({
  name  = "float-feishu-image-preview",
  match = { class = "^$", title = "^图片$", xwayland = true },
  float = true,
})

-- 飞书:会话记录(Wayland 原生,class 为空,靠 title 区分)
hl.window_rule({
  name  = "float-feishu-chat-history",
  match = { class = "^$", title = ".*会话记录$" },
  float = true,
})

hl.window_rule({ name = "float-blueman-manager",     match = { class = "blueman-manager" },          float = true })
hl.window_rule({ name = "float-pavucontrol",         match = { class = "org.pulseaudio.pavucontrol" }, float = true })
hl.window_rule({ name = "float-nm-connection-editor", match = { class = "nm-connection-editor" },     float = true })
hl.window_rule({ name = "float-localsend",           match = { class = "localsend" },                float = true })
hl.window_rule({ name = "float-dolphin",             match = { class = "org.kde.dolphin" },          float = true })
hl.window_rule({ name = "float-telegram",            match = { class = "org.telegram.desktop" },     float = true })

-- Fcitx5 候选框:XWayland 顶层窗口,去圆角并 pin 防止被 special workspace 盖住
hl.window_rule({
  name     = "fcitx5-input-window",
  match    = { title = "^Fcitx5 Input Window$" },
  pin      = true,
  rounding = 0,
})

----------------------------------------------------------------------
-- 工作区规则示例:"无间隙当仅一个窗口时"(需要时取消注释)
-- 文档: https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
----------------------------------------------------------------------
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ name = "no-gaps-wtv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
-- hl.window_rule({ name = "no-gaps-f1",   match = { float = false, workspace = "f[1]" },   border_size = 0, rounding = 0 })
