#!/usr/bin/env bash
#
# 把 config/sddm/themes/ 下的主题装到 /usr/share/sddm/themes/。
#
# 为什么是拷贝而不是软链:SDDM 的 greeter 以 sddm 用户运行,读不到 /home/sjet,
# 软链过去会在登录界面变成一片空白。背景图同理,必须拷进主题目录。
#
#   ./install.sh            # 安装 + 切换为该主题
#   ./install.sh --no-switch  # 只安装,不改 sddm 配置

set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

THEME=hyprlock
DEST=/usr/share/sddm/themes/$THEME
# 与 hyprlock.conf 保持同两张图:DP-1(横) 用 Primary,HDMI-A-1(竖) 用 Secondary。
# 主题按屏幕方向选,所以这里横竖各拷一张。
WALL_LANDSCAPE="$HOME/Pictures/Wallpapers/M31_Primary.png"
WALL_PORTRAIT="$HOME/Pictures/Wallpapers/M31_Secondary.png"

for w in "$WALL_LANDSCAPE" "$WALL_PORTRAIT"; do
    [[ -f $w ]] || { echo "找不到壁纸: $w" >&2; exit 1; }
done

sudo rm -rf "$DEST"
sudo mkdir -p "$DEST"
sudo cp themes/$THEME/{Main.qml,metadata.desktop,theme.conf} "$DEST/"
sudo cp "$WALL_LANDSCAPE" "$DEST/background.png"
sudo cp "$WALL_PORTRAIT"  "$DEST/background-portrait.png"
sudo chmod -R a+rX "$DEST"
echo "已安装到 $DEST"

if [[ ${1:-} != --no-switch ]]; then
    sudo sed -i "s/^Current=.*/Current=$THEME/" /etc/sddm.conf.d/kde_settings.conf
    echo "已切换 sddm 主题为 $THEME"
fi

echo
echo "预览(不影响当前会话):"
echo "  sddm-greeter-qt6 --test-mode --theme $DEST"
