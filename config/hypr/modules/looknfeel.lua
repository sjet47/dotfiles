-- 外观与手感:布局/装饰/动画/杂项
-- 文档: https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
  -- https://wiki.hypr.land/Configuring/Basics/Variables/#general
  general = {
    gaps_in  = 3,
    gaps_out = 6,

    border_size = 1,

    col = {
      active_border   = "rgba(ffffff80)",
      inactive_border = "rgba(ffffff10)",
    },

    -- 是否允许点击/拖拽边框和间隙来缩放窗口
    resize_on_border = false,

    -- 打开前请先看 https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/
    allow_tearing = false,

    layout = "dwindle",

    no_focus_fallback = true,
  },

  -- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
  decoration = {
    rounding       = 14,
    rounding_power = 4,

    active_opacity   = 1.0,
    inactive_opacity = 1.0,

    dim_inactive = true,
    dim_strength = 0.08,

    shadow = {
      enabled      = true,
      range        = 8,
      render_power = 2,
      offset       = { 0, 4 },
      color        = "rgba(00000080)",
    },

    -- https://wiki.hypr.land/Configuring/Basics/Variables/#blur
    blur = {
      enabled           = false,
      size              = 8,
      passes            = 3,
      new_optimizations = true,
      xray              = false,
      noise             = 0.02,
      contrast          = 0.9,
      brightness        = 0.9,
      vibrancy          = 0.25,
      vibrancy_darkness = 0.1,
    },
  },

  animations = {
    enabled = true,
  },

  -- https://wiki.hypr.land/Configuring/Basics/Variables/#misc
  misc = {
    force_default_wallpaper = 0,    -- 0/1 关闭吉祥物壁纸
    disable_hyprland_logo   = true, -- 关闭随机 logo 背景
  },

  xwayland = {
    force_zero_scaling = true,
  },

  -- 布局:https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
  dwindle = {
    force_split    = 2,    -- 新窗口固定放在右/下侧 (0=按比例 1=左/上 2=右/下)
    preserve_split = true, -- 关闭窗口后其余窗口保留原 split 方向
    smart_split    = false,
  },

  -- 布局:https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
  master = {
    new_status = "master",
  },
})

-- 动画曲线,见 https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 } } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

-- 图层规则(anonymous/named layer rules)
hl.layer_rule({ name = "vicinae", match = { namespace = "vicinae" }, blur = true, ignore_alpha = 0,   no_anim = true })
hl.layer_rule({ name = "waybar",  match = { namespace = "waybar" },  blur = true, ignore_alpha = 0.4 })
