-- 输入设备:键盘/鼠标/触摸板/手势
-- 文档: https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
  input = {
    kb_layout = "us",

    repeat_rate  = 30,
    repeat_delay = 200,

    follow_mouse = 2,

    sensitivity = 0, -- -1.0 ~ 1.0,0 表示不修改

    touchpad = {
      natural_scroll = false,
    },
  },
})

-- 手势,见 https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({
  fingers   = 3,
  direction = "horizontal",
  action    = "workspace",
})

-- 单设备配置示例,见 https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
hl.device({
  name        = "epic-mouse-v1",
  sensitivity = -0.5,
})
