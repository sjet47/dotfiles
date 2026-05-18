-- Hyprland 配置入口 (Lua, Hyprland 0.55+)
-- 文档: https://wiki.hypr.land/Configuring/Start/
--
-- 每个 require() 是独立的 Lua scope:某个模块出错不会中断其他模块。
-- 详见 https://wiki.hypr.land/Configuring/Start/#require

require("modules.monitors")
require("modules.env")
require("modules.looknfeel")
require("modules.input")
require("modules.windowrules")
require("modules.binds")
require("modules.autostart")

-- 机器本地覆盖配置(local/ 已被 gitignore;不存在时静默跳过)
-- 参考模板见 local/example.lua
pcall(require, "local.init")
