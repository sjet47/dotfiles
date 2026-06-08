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
    hyprpaper                    # 壁纸
    hyprlock                     # 锁屏
    hypridle                     # 空闲管理(配合 hyprlock)
    hyprpicker                   # 取色器
    xdg-desktop-portal-hyprland  # 截图/录屏/文件选择 portal 后端
    xwayland-satellite           # 按需启动的 Xwayland
    polkit-gnome                 # 图形化授权代理
    sddm                         # 登录/显示管理器
)

# ── 状态栏 / 启动器 / 通知 / 注销 ──────────────────────────────
SHELL_UI=(
    waybar       # 顶部状态栏
    vicinae-bin  # 应用启动器(AUR,配置里默认用它)
    wofi         # 备用 dmenu 式启动器
    mako         # 通知守护
    wlogout      # 注销/电源菜单
)

# ── 截图 / 录屏 / 剪贴板 ───────────────────────────────────────
CAPTURE=(
    grim             # 截图后端
    slurp            # 区域选择
    satty            # 截图标注
    swappy           # 截图标注(备选)
    wl-clipboard     # wl-copy / wl-paste
    cliphist          # 剪贴板历史
    wl-screenrec-git  # 录屏(AUR)
)

# ── 音频 / 媒体 / 电源 / 蓝牙 ──────────────────────────────────
SYSTEM=(
    pamixer                # 音量控制(快捷键)
    pavucontrol            # 图形音量面板
    playerctl              # 媒体播放控制(快捷键)
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
    ttf-maplemono-nf-cn-unhinted
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
    "${SHELL_UI[@]}"
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
