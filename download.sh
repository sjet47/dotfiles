#!/bin/bash

## Download with package manager
os_name=$(uname)
if [[ $os_name == "Linux" ]]
then
	issue=($(cat /etc/issue))
	disv=$issue
elif [[ $os_name == "Darwin" ]]
then
	disv="macOS"
fi
if [[ $disv == "Arch" ]]
then
	yay -Syyu --noconfirm zsh lsd wget
elif [[ $disv == "Ubuntu" ]]
then
	sudo apt update
	sudo apt upgrade -y
	sudo apt install -y zsh lsd
elif [[ $disv == "macOS" ]]

then
	brew update
	brew upgrade
	brew install zsh lsd
fi
