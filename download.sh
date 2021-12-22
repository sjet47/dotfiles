#!/bin/bash

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
	yay -Syyu --noconfirm zsh git lsd bat enca
elif [[ $disv == "Ubuntu" ]]
then
	sudo apt update
	sudo apt upgrade -y
	sudo apt install zsh git lsd bat enca
elif [[ $disv == "macOS" ]]

then
	brew update
	brew upgrade
	brew install zsh git lsd bat enca
fi
