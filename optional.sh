#!/bin/bash

## Download with package manager

lbp=$HOME/.local/bin
os_name=$(uname)
arch=$(uname -m)
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
	yay -Syyu --noconfirm enca bat python3 python-pip
elif [[ $disv == "Ubuntu" ]]
then
	sudo apt update
	sudo apt upgrade -y
	sudo apt install -y enca bat python3 python-pip
elif [[ $disv == "macOS" ]]

then
	brew update
	brew upgrade
	brew install enca bat python3 python-pip
fi

# Install pls
if [[ $arch == "x86_64" ]]
then
	wget https://github.com/chenjiandongx/pls/releases/download/v0.1.4/pls_darwin_amd64 -O $lbp/pls
	chmod +x $HOME/.bin/pls
	$lbp/pls upgrade
fi

## Download with pip
pip install html2text --user
