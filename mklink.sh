#!/bin/bash

function mklnk(){
	if [[ ! -e $HOME/.$1 ]]; then
    ln -s $HOME/dotfiles/$1 $HOME/.$1
	fi
}

function mkd(){
  if [[ ! -e $HOME/$1 ]]; then
    mkdir -p -v $HOME/$1
  fi
}

mklnk gitconfig
mklnk npmrc
mklnk pip
mklnk vim
mklnk vimrc
mklnk zshrc
mklnk gdbinit
mklnk tmux.conf

# local profile
touch $HOME/.profile

mkd .local/bin
mkd .local/lib
mkd .local/log/update
mkd .backup
mkd .vimdir/swp
mkd .vimdir/bak
mkd .vimdir/undo
