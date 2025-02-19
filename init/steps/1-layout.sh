#!/bin/bash

set -eo pipefail

source "$(dirname $0)/common.sh"

mkdir_targets=(
    .local/bin
    .local/lib
    .local/log/update/{pip,yay,apt,brew}
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

    # local profile
    touch "$HOME/.profile"
}

main
