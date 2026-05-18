-- 机器本地配置模板
-- ============================================================
-- 复制本文件为 local/init.lua 并按本机情况修改。
-- local/ 目录除本文件外都被 gitignore,init.lua 不入库。
-- 入口 hyprland.lua 通过 pcall(require, "local.init") 加载,缺失时静默跳过。
-- local 配置最后加载,可覆盖前面模块的设置(如显示器布局)。

-- 显示器(覆盖 modules/monitors.lua 的 fallback 规则)
-- hl.monitor({ output = "DP-1",     mode = "preferred", position = "0x0",    scale = 1.25 })
-- hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "1920x0", scale = 1.25, transform = 1 })

-- 本机自启动
-- hl.on("hyprland.start", function()
--   hl.exec_cmd("~/.config/hypr/scripts/wallpaper.sh")
--   hl.exec_cmd("[workspace 1 silent] uwsm-app -- code ~/project")
-- end)
