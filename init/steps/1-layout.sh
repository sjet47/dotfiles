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

    # local profile
    touch "$HOME/.profile"
}

main
