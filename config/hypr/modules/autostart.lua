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
  -- KeePassXC 是 Qt6 原生 Wayland,而 uwsm-app 建的是 scope(继承 Hyprland 环境),
  -- 会吃到 env.lua 的 QT_SCALE_FACTOR=1.5 并和显示器 scale 叠乘成 2.25 倍。
  -- QT_SCALE_FACTOR 是 Qt 里少数不分后端、无脑相乘的变量,只该给 XWayland 下的
  -- Qt 应用(如 fcitx5 候选框),凡是走原生 Wayland 的 Qt 应用都必须摘掉它。
  hl.exec_cmd("uwsm-app -- env -u QT_SCALE_FACTOR keepassxc")
end)
