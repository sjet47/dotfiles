#!/bin/bash

function mklnk() {
	dst = "$HOME/.$1"
  if [[ -e $dst ]]; then
		echo $dst already exist, backup to $dst.bak
		mv $dst $dst.bak
  fi
	ln -s "$HOME/dotfiles/$1" $dst
}

function mkd() {
  if [[ ! -e $HOME/$1 ]]; then
    mkdir -p -v "$HOME/$1"
  fi
}

mklnk gitconfig
mklnk npmrc
mklnk pip
mklnk vimrc
mklnk zshrc
mklnk gdbinit
mklnk tmux.conf
mklnk wezterm.lua

# local profile
touch "$HOME/.profile"

mkd .local/bin
mkd .local/lib
mkd .local/log/update/pip
mkd .local/log/update/yay
mkd .local/log/update/apt
mkd .local/log/update/brew
mkd .backup
mkd .config

# Link neovim
ln -s "$HOME/dotfiles/$1" "$HOME/.config/nvim"
