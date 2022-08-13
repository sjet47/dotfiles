#!/bin/bash

LBP=$HOME/.local/bin
ARCH=$(uname -m)

getbin() {
  wget "$1" -O $LBP/$2
  chmod +x $LBP/$2
}

## Get distribution name
os_name=$(uname)
if [[ $os_name == "Linux" ]]
then
  disv=$(cat /etc/issue | awk '{print $1}')
elif [[ $os_name == "Darwin" ]]
then
  disv="macOS"
fi

## Install necessary packages
if [[ $disv == "Arch" ]]
then
	if [[ $(whoami) == "root" ]]
	then
	pacman -Syyu zsh lsd wget tmux tmuxinator moreutils pyenv nvm enca lolcat
	else
	yay -Syyu zsh lsd wget tmux tmuxinator moreutils pyenv nvm enca lolcat
	fi
elif [[ $disv == "Ubuntu" ]]
then
	if [[ $(whoami) == "root" ]]
	then
		apt update
		apt upgrade -y
		apt install -y zsh lsd wget tmux moreutils pyenv enca lolcat
	else
	sudo apt update
	sudo apt upgrade -y
	sudo apt install -y zsh lsd wget tmux moreutils pyenv enca lolcat
	fi
if [[ $ARCH == "x86_64" ]]
then
	git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv
	cd $HOME/.pyenv && src/configure && make -C src
	echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $HOME/.profile
	echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> $HOME/.profile
fi
elif [[ $disv == "macOS" ]]
then
	brew update
	brew upgrade
	brew install zsh lsd wget tmux moreutils pyenv enca lolcat
fi

## Zsh

# oh-my-zsh
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
# zsh-completions
git clone https://github.com/zsh-users/zsh-completions $HOME/.oh-my-zsh/custom/plugins/zsh-completions
# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions


## Install other packages

# Starship
curl -sS https://starship.rs/install.sh | sudo sh

# Tmux Plugin Manager
git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
tmux source $HOME/.tmux.conf
