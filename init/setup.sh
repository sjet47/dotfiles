#!/bin/bash

# DO NOT RUN AS ROOT

tlog() {
    echo $(date "+%Y-%m-%dT%H:%M:%S%:z")'|'"$@"
}

# Required packages, will be install via system package manager
required_common=(zsh lsd bat vim neovim make cmake gdb tmux docker valgrind moreutils)
# Required packages, need to install in different ways on different OS
required_spec=(mcfly starship pyenv rustup)

# Optional packages, use "-o" to install via system package manager
optional_common=(vifm xclip enca rclone ffmpeg rsync p7zip html2text)
# Optional packages, need to install in different ways on different OS
optional_spec=(ninja)

if [ "$1" == "-o" ]; then
    required_common+=(${optional_common[@]})
    required_spec+=(${optional_spec[@]})
fi

tlog "The following packages will be installed:" "${required_common[@]}" "${required_spec[@]}"

## Get distribution name
os_name=$(uname)
if [[ $os_name == "Linux" ]]; then
    disv=$(awk '{print $1}' </etc/issue)
elif [[ $os_name == "Darwin" ]]; then
    disv="macOS"
fi

tlog "Detected distribution: $disv"

# Make symbol link and dir at first
tlog "make symbol link"
source slink.sh

# Install on ArchLinux
if [[ $disv == "Arch" ]]; then
    installPkg() {
        yay -Syyu $@
    }

    installPkg mcfly starship pyenv

    if [ "$1" == "-o" ]; then
        installPkg ninja
    fi

    # Still have rust to install

elif [[ $disv == "Ubuntu" ]]; then
    sudo apt update
    sudo apt upgrade -y
    installPkg() {
        sudo apt install -y $@
    }

    # mcfly
    tlog "Install mcfly"
    curl -LSfs https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh | sudo sh -s -- --git cantino/mcfly

    # Starship
    tlog "Install Starship"
    curl -sS https://starship.rs/install.sh | sudo sh

    # pyenv
    tlog "Install pyenv"
    curl https://pyenv.run | bash

    if [ "$1" == "-o" ]; then
        # ninja
        tlog "Install ninja"
        cd /tmp && wget https://github.com/ninja-build/ninja/releases/download/v1.11.1/ninja-linux.zip
        unzip ninja-linux.zip
        sudo cp ninja /usr/local/bin/ninja
    fi

    # Still have rust to install

elif [[ $disv == "macOS" ]]; then
    brew update
    brew upgrade
    installPkg() {
        brew install $@
    }

    installPkg mcfly starship pyenv

    if [ "$1" == "-o" ]; then
        installPkg ninja
    fi

    # Still have rust to install
fi

# Install common required and optional packages
installPkg ${required_common[@]}

# Install rust
tlog "Install rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

## Zsh Plugins
ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$ZSH/custom"

# oh-my-zsh
tlog "Install oh-my-zsh"
git clone https://github.com/ohmyzsh/ohmyzsh.git "$ZSH"

# Install optional
if [ "$1" == "-o" ]; then
    # zsh-completions
    tlog "Install zsh-completions"
    git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"

    # zsh-syntax-highlighting
    tlog "Install zsh-syntax-highlighting"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

    # zsh-autosuggestions
    tlog "Install zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

    # Tmux Plugin Manager
    TMUX_PLUGINS="$HOME/.tmux/plugins"
    mkdir -p "$TMUX_PLUGINS"
    tlog "Install Tmux Plugin Manager"
    git clone https://github.com/tmux-plugins/tpm "$TMUX_PLUGINS/tpm"

    tmux source "$HOME/.tmux.conf"
fi

# Change shell
chsh -s /bin/zsh

# Open zsh
zsh
