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
  -- 桌面 shell:OSD + 通知守护(替代 mako),整个桌面只此一个 quickshell 实例。
  -- mako 的包和 config/mako/ 暂时留着方便回退。
  hl.exec_cmd("uwsm-app -- qs")
end)
