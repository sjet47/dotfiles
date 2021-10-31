#!/bin/zsh

# Install powerlevel10k
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
git clone --depth=1 git://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Define make link function
function mklnk(){
	if [[ -e $HOME/.$1 ]]; then
		mv $HOME/.$1 $HOME/.$1.bak
	fi
	ln -s $HOME/dotfiles/$1 $HOME/.$1
}

mklnk gitconfig
mklnk npmrc
mklnk pip
mklnk vim
mklnk vimrc
mklnk zshrc
mklnk gdbinit

# User profile
touch $HOME/.profile

# User binary
if [[ ! -e $HOME/.bin ]]; then
	mkdir $HOME/.bin
fi

# User scripts
if [[ ! -e $HOME/.script ]]; then
	mkdir $HOME/.script
fi

# vimdir
if [[ ! -e $HOME/.vimdir ]]; then
	mkdir $HOME/.vimdir
	mkdir $HOME/.vimdir/swp
	mkdir $HOME/.vimdir/bak
	mkdir $HOME/.vimdir/undo
fi

# Load zshrc
source $HOME/.zshrc

# Configure powerlevel10k
p10k configure
