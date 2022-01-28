#!/bin/bash

source ./lib.sh

if [[ $disv == "Arch" ]]
then
	yay -Syyu --noconfirm zsh lsd wget tmux moreutils diff-so-fancy
elif [[ $disv == "Ubuntu" ]]
then
	sudo apt update
	sudo apt upgrade -y
	sudo apt install -y zsh lsd wget tmux moreutils
if [[ $ARCH == "x86_64" ]]
then
	getbin https://github.com/so-fancy/diff-so-fancy/releases/download/v1.4.2/diff-so-fancy diff-so-fancy
fi

elif [[ $disv == "macOS" ]]
then
	brew update
	brew upgrade
	brew install zsh lsd wget tmux moreutils diff-so-fancy
fi
