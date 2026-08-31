-- 自启动
-- 文档: https://wiki.hypr.land/Configuring/Basics/Autostart/
--
-- 与机器相关的自启动(按工作区拉起特定应用等)放在 local/init.lua。

hl.on("hyprland.start", function()
  hl.exec_cmd("systemctl --user --no-block start hypridle.service")
  hl.exec_cmd("systemctl --user --no-block start waybar.service")
  hl.exec_cmd("uwsm-app -- awww-daemon")
  -- 候选框是 XWayland 顶层窗口(见 windowrules.lua),需要 QT_SCALE_FACTOR 才不会按 1x 渲染。
  -- 全局已不设该变量,这里是唯一的显式消费者。
  hl.exec_cmd("uwsm-app -- env QT_SCALE_FACTOR=1.5 fcitx5 -d")
  hl.exec_cmd("uwsm-app -- gnome-keyring-daemon --start --components=secrets,ssh,pkcs11")
  hl.exec_cmd("systemctl --user --no-block start vicinae.service")
  hl.exec_cmd("uwsm-app -- keepassxc")
  -- 桌面 shell:OSD + 通知守护 + 电源菜单 + 屏保,整个桌面只此一个 quickshell 实例。
  -- (config/quickshell/bar/ 里有一条做完的状态栏,但当前没接进 shell.qml —— 用户
  --  2026-08-27 决定先继续用 waybar,所以上面的 waybar.service 还留着。)
  -- QT_QPA_PLATFORMTHEME=gtk3 是**托盘图标必需的**:Qt 不读 gtk-icon-theme-name,不设这个
  -- 就只认 hicolor,主题里的图标(fcitx 的 input-keyboard-symbolic 之类)全部退化成洋红
  -- 方格占位(实测 Quickshell.iconPath 直接返回空串)。插件来自 libqgtk3.so,已装。
  -- 只给 qs 设,不写进 env.lua —— 全局设会让所有 Qt 应用都跟着 GTK 主题走,那是另一件事。
  hl.exec_cmd("uwsm-app -- env QT_QPA_PLATFORMTHEME=gtk3 qs")
end)
