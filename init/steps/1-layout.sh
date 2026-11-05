#!/bin/bash

set -e

source "$(dirname $0)/common.sh"

mkdir_targets=(
    .local/bin
    .local/lib
    .local/log/update/{pip,yay,apt,brew}
    .local/share/applications
    .backup
)

slink_targets=(
    config
    pip
    gitconfig
    npmrc
    vimrc
    zshrc
    gdbinit
    tmux.conf
    wezterm.lua
)

# 用户级 .desktop 覆盖(修 Wayland 后端 / Qt 缩放)。
# ~/.local/share/applications 里混着 Steam 游戏、Chrome PWA、mimeinfo.cache 等
# 自动生成的条目,不能整目录 symlink,只能逐文件链接。
function link_desktop_entries() {
    local src_dir="$HOME/dotfiles/local/share/applications"
    local dst_dir="$HOME/.local/share/applications"

    info "link desktop entries"
    for src in "$src_dir"/*.desktop; do
        local dst="$dst_dir/$(basename "$src")"
        info "make symbol link $src -> $dst" 3
        ln -sfn "$src" "$dst"
    done
    ok "link desktop entries"
    echo
}

# 用户级图标补丁。上游若只装 scalable SVG,静态构建的 Qt 程序(Vicinae)拿不到图标:
# 它没有 SVG icon engine,`QIcon::fromTheme()` 对纯 SVG 的图标名返回 null。
# 这里按 hicolor 尺寸目录补 PNG,并逐文件软链进 ~/.local/share/icons
# (同名文件可能来自别的主题/包,不能整目录 symlink)。
function link_icons() {
    local src_root="$HOME/dotfiles/local/share/icons"
    local dst_root="$HOME/.local/share/icons"

    info "link icons"
    for src in "$src_root"/hicolor/*/apps/*; do
        local rel="${src#$src_root/}"
        local dst="$dst_root/$rel"
        info "make symbol link $src -> $dst" 3
        mkdir -p "$(dirname "$dst")"
        ln -sfn "$src" "$dst"
    done
    ok "link icons"
    echo
}

# Rime 用户配置。~/.local/share/fcitx5/rime 里混着 userdb 和 build 产物,
# 不能整目录 symlink,只能逐文件链接。雾凇词库本身来自 pacman 包。
function link_rime_config() {
    local src_dir="$HOME/dotfiles/local/share/fcitx5/rime"
    local dst_dir="$HOME/.local/share/fcitx5/rime"

    info "link rime config"
    mkdir -p "$dst_dir"
    for src in "$src_dir"/*.yaml; do
        local dst="$dst_dir/$(basename "$src")"
        info "make symbol link $src -> $dst" 3
        ln -sfn "$src" "$dst"
    done
    ok "link rime config"
    echo
}

function mkdir_home() {
    info "make directory $HOME/$1" 3
    mkdir -p -v "$HOME/$1"
}

function mkdirs() {
    info "make directories"
    for target in "${mkdir_targets[@]}"; do
        mkdir_home $target
    done
    ok "make directories"
    echo

}

function slink() {
    local src="$HOME/dotfiles/$1"
    local dst="$HOME/.$1"
    info "make symbol link $src -> $dst" 3
    if [[ -e $dst ]]; then
        warn "$dst already exist, backup to $dst.bak" 6
        mv $dst $dst.bak
    fi
    ln -s $src $dst
}

function make_slinks() {
    info "make symbol links"
    for target in "${slink_targets[@]}"; do
        slink $target
    done
    ok "make symbol links"
    echo
}

function main() {
    make_slinks
    mkdirs
    link_desktop_entries
    link_icons
    link_rime_config

    # local profile
    touch "$HOME/.profile"
}

main
