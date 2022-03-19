#!/bin/bash

LBP=$HOME/.local/bin
ARCH=$(uname -m)

getbin() {
  wget "$1" -O $LBP/$2
  chmod +x $LBP/$2
}

# Get distribution name
os_name=$(uname)
if [[ $os_name == "Linux" ]]
then
  disv=$(cat /etc/issue | awk '{print $1}')
elif [[ $os_name == "Darwin" ]]
then
  disv="macOS"
fi

# Install necessary packages
if [[ $disv == "Arch" ]]
then
	if [[ $(whoami) == "root" ]]
	then
	pacman -Syyu zsh lsd wget tmux moreutils diff-so-fancy pyenv enca
	else
	yay -Syyu zsh lsd wget tmux moreutils diff-so-fancy pyenv enca
	fi
elif [[ $disv == "Ubuntu" ]]
then
	if [[ $(whoami) == "root" ]]
	then
		apt update
		apt upgrade -y
		apt install -y zsh lsd wget tmux moreutils pyenv enca
	else
	sudo apt update
	sudo apt upgrade -y
	sudo apt install -y zsh lsd wget tmux moreutils pyenv enca
	fi
if [[ $ARCH == "x86_64" ]]
then
	getbin https://github.com/so-fancy/diff-so-fancy/releases/download/v1.4.2/diff-so-fancy diff-so-fancy

	git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv
	cd $HOME/.pyenv && src/configure && make -C src
	echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $HOME/.profile
	echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> $HOME/.profile
fi
elif [[ $disv == "macOS" ]]
then
	brew update
	brew upgrade
	brew install zsh lsd wget tmux moreutils diff-so-fancy pyenv enca
fi

# Install powerlevel10k
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Install Tmux Plugin Manager
git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
tmux source $HOME/.tmux.conf
