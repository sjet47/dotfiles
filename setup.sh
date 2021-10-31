#!/bin/zsh

function mklnk(){
	if [[ -e $HOME/.$1 ]]; then
		mv $HOME/.$1 $HOME/.$1.bak
	fi
	ln -s $HOME/dotfiles/$1 $HOME/.$1
}

source installp10k.sh

mklnk gitconfig
mklnk npmrc
mklnk pip
mklnk vim
mklnk vimrc
mklnk zshrc
mklnk gdbinit
touch $HOME/.profile
if [[ ! -e $HOME/.bin ]]; then
	mkdir $HOME/.bin
fi

if [[ ! -e $HOME/.script ]]; then
	mkdir $HOME/.script
fi

if [[ ! -e $HOME/.vimdir ]]; then
	mkdir $HOME/.vimdir
	mkdir $HOME/.vimdir/swp
	mkdir $HOME/.vimdir/bak
	mkdir $HOME/.vimdir/undo
fi

source $HOME/.zshrc
p10k configure
