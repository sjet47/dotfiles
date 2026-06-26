-- 自启动
-- 文档: https://wiki.hypr.land/Configuring/Basics/Autostart/
--
-- 与机器相关的自启动(按工作区拉起特定应用等)放在 local/init.lua。

hl.on("hyprland.start", function()
  hl.exec_cmd("systemctl --user --no-block start hypridle.service")
  hl.exec_cmd("systemctl --user --no-block start mako.service")
  hl.exec_cmd("systemctl --user --no-block start waybar.service")
  hl.exec_cmd("uwsm-app -- awww-daemon")
  hl.exec_cmd("uwsm-app -- fcitx5 -d")
  hl.exec_cmd("uwsm-app -- gnome-keyring-daemon --start --components=secrets,ssh,pkcs11")
  hl.exec_cmd("systemctl --user --no-block start vicinae.service")
  hl.exec_cmd("uwsm-app -- keepassxc")
end)
