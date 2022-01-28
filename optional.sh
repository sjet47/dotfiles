#!/bin/bash

source ./lib.sh

## Download with package manager
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
	getbin https://github.com/chenjiandongx/pls/releases/download/v0.1.4/pls_darwin_amd64 /pls
	$lbp/pls upgrade
fi

## Download with pip
python3 -m pip install html2text
