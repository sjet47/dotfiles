-- 快捷键
-- 文档: https://wiki.hypr.land/Configuring/Basics/Binds/
--       https://wiki.hypr.land/Configuring/Basics/Dispatchers/

local vars = require("modules.vars")
local mod  = vars.mainMod

----------------------------------------------------------------------
-- 工具类
----------------------------------------------------------------------

hl.bind(mod .. " + ALT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + ALT + M", hl.dsp.exec_cmd("wlogout -p layer-shell"))

hl.bind(mod .. " + Q",      hl.dsp.window.close())
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd("uwsm-app -- " .. vars.terminal))
hl.bind(mod .. " + E",      hl.dsp.exec_cmd(vars.fileManager))
hl.bind(mod .. " + T",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + space",  hl.dsp.exec_cmd(vars.menu))
hl.bind(mod .. " + P",      hl.dsp.window.pseudo())        -- dwindle
hl.bind(mod .. " + S",      hl.dsp.layout("togglesplit"))  -- dwindle

-- 剪贴板历史
hl.bind(mod .. " + V", hl.dsp.exec_cmd("vicinae deeplink 'vicinae://launch/clipboard/history'"))

-- 截图:smart(拉框,<20px² 自动吸附窗口/显示器) / region / window / fullscreen
hl.bind("PRINT",             hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh region"))
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh window"))
hl.bind(mod .. " + SHIFT + F", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh fullscreen"))

-- 录屏:region(默认拉框) / window / fullscreen,再次按下停止并保存到 ~/Videos
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenrecord.sh"))

----------------------------------------------------------------------
-- 平铺:焦点 / 移动 / 缩放 / 工作区
----------------------------------------------------------------------

-- 焦点移动 (hjkl)
hl.bind(mod .. " + h", hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. " + l", hl.dsp.focus({ direction = "r" }))
hl.bind(mod .. " + k", hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + j", hl.dsp.focus({ direction = "d" }))

-- 窗口移动 (SHIFT + hjkl)
hl.bind(mod .. " + SHIFT + h", hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + SHIFT + l", hl.dsp.window.move({ direction = "r" }))
hl.bind(mod .. " + SHIFT + k", hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + SHIFT + j", hl.dsp.window.move({ direction = "d" }))

-- 切换工作区 / 把窗口移到工作区 (1-10)
for i = 1, 10 do
  local key = i % 10 -- 10 映射到按键 0
  hl.bind(mod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

-- 缩放当前窗口 (SHIFT + 方向键)
hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -40, y = 0,   relative = true }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.resize({ x = 40,  y = 0,   relative = true }))
hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = -40, relative = true }))
hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }))

-- 特殊工作区(scratchpad)
hl.bind(mod .. " + grave",         hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(mod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:scratchpad" }))

-- 在已有工作区间循环
hl.bind(mod .. " + TAB",         hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }))

-- 鼠标拖拽移动/缩放窗口
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

----------------------------------------------------------------------
-- 多媒体键(笔记本音量/亮度)
----------------------------------------------------------------------

-- locked: 锁屏时仍生效;repeating: 按住可连发
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- 需要 playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
