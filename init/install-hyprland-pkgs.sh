#!/bin/bash
#
# install-hyprland-pkgs.sh
#
# 一键(重)装本机 Hyprland 桌面环境所需的全部软件包。
# 这份清单是从迁移完成后的系统里(pacman -Qe)梳理出来的,
# 包含官方仓库与 AUR 包,统一用 paru 安装。
#
# 用法:
#   ./install-hyprland-pkgs.sh           # 安装(已装的会跳过)
#   ./install-hyprland-pkgs.sh --extras  # 额外装备选终端等可选包
#
# 注意:这里只装"包",dotfiles 配置仍由仓库里的 stow/链接步骤负责。

set -euo pipefail

# ── 核心:合成器、会话、portal、polkit ──────────────────────────
CORE=(
    hyprland                     # Wayland 合成器本体
    uwsm                         # 通用 Wayland 会话管理(autostart/binds 里 uwsm-app 拉起应用)
    awww                         # 壁纸守护(wallpaper.sh / autostart 的 awww-daemon 实际使用)
    hyprpaper                    # 壁纸(备用,当前配置默认用 awww)
    hyprlock                     # 锁屏
    hypridle                     # 空闲管理(配合 hyprlock)
    hyprpicker                   # 取色器(截图冻结画面)
    xdg-desktop-portal-hyprland  # 截图/录屏/文件选择 portal 后端
    xwayland-satellite           # 按需启动的 Xwayland
    gnome-keyring                # 密钥环 / SSH agent(autostart + env.lua 的 SSH_AUTH_SOCK)
    polkit-gnome                 # 图形化授权代理
    sddm                         # 登录/显示管理器
)

# ── 输入法(fcitx5,env.lua + autostart 配置)────────────────────
INPUT=(
    fcitx5                  # 输入法框架
    fcitx5-chinese-addons   # 拼音/中文输入
    fcitx5-configtool       # 图形配置
    fcitx5-gtk              # GTK 应用集成
    fcitx5-qt               # Qt 应用集成
)

# ── 状态栏 / 启动器 / 通知 / 注销 ──────────────────────────────
SHELL_UI=(
    waybar       # 顶部状态栏
    vicinae-bin  # 应用启动器(AUR,配置里默认用它)
    wofi         # 备用 dmenu 式启动器
    mako         # 通知守护
    wlogout      # 注销/电源菜单
)

# ── 桌面应用:文件管理 / 密码 ──────────────────────────────────
APPS=(
    dolphin    # 文件管理器(vars.lua,SUPER+E)
    keepassxc  # 密码管理(autostart + windowrules)
)

# ── 截图 / 录屏 / 剪贴板 ───────────────────────────────────────
CAPTURE=(
    grim             # 截图后端
    slurp            # 区域选择
    satty            # 截图标注
    swappy           # 截图标注(备选)
    wl-clipboard     # wl-copy / wl-paste
    cliphist          # 剪贴板历史
    wl-screenrec-git  # 录屏(archlinuxcn / AUR)
    jq               # 脚本解析 hyprctl JSON(截图/录屏选区)
    libnotify        # notify-send(截图/录屏通知)
    python-gobject   # recording-border.py(录屏范围边框)
    python-cairo     # recording-border.py 绘制
    gtk3             # recording-border.py(GTK3 + layer-shell)
    gtk-layer-shell  # recording-border.py 覆盖层
)

# ── 音频 / 媒体 / 电源 / 蓝牙 ──────────────────────────────────
SYSTEM=(
    wireplumber            # 音量快捷键用的 wpctl(binds.lua)
    pamixer                # 音量控制(备用)
    pavucontrol            # 图形音量面板
    playerctl              # 媒体播放控制(快捷键)
    brightnessctl          # 亮度快捷键(binds.lua,笔记本背光)
    power-profiles-daemon  # 电源模式切换
    blueman                # 蓝牙托盘
    bluez-utils            # bluetoothctl 等
    bluez-obex             # 蓝牙文件传输
)

# ── 终端 ───────────────────────────────────────────────────────
TERMINAL=(
    kitty  # 配置里默认终端
)

# ── 字体(状态栏图标 / CJK / emoji 都依赖)─────────────────────
FONTS=(
    ttf-maplemono-nf-cn-unhinted  # Maple Mono NF CN(kitty 默认字体,自带 Nerd/CJK)
    noto-fonts       # Noto Sans(hyprlock 时间/日期/输入框)
    noto-fonts-cjk
    noto-fonts-extra
    ttf-apple-emoji
    ttf-cascadia-code
    ttf-cascadia-code-nerd
    ttf-jetbrains-mono
    ttf-jetbrains-mono-nerd
    ttf-nunito
)

# ── 可选:备选终端 + 其它顺手装的工具(--extras 才装)──────────
EXTRAS=(
    alacritty
    foot
    ghostty
    fastfetch  # 系统信息
)

PKGS=(
    "${CORE[@]}"
    "${INPUT[@]}"
    "${SHELL_UI[@]}"
    "${APPS[@]}"
    "${CAPTURE[@]}"
    "${SYSTEM[@]}"
    "${TERMINAL[@]}"
    "${FONTS[@]}"
)

if [[ "${1:-}" == "--extras" ]]; then
    PKGS+=("${EXTRAS[@]}")
fi

if ! command -v paru >/dev/null 2>&1; then
    echo "错误:未找到 paru,请先安装 paru(AUR helper)再运行本脚本。" >&2
    exit 1
fi

echo "即将安装 ${#PKGS[@]} 个包(已安装的会自动跳过)..."
paru -S --needed "${PKGS[@]}"

echo
echo "完成。后续提醒:"
echo "  - 启用登录管理器:  sudo systemctl enable sddm.service"
echo "  - 蓝牙服务:        sudo systemctl enable --now bluetooth.service"
echo "  - 电源模式守护:    sudo systemctl enable --now power-profiles-daemon.service"
