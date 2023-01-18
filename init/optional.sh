#!/bin/bash

# DO NOT RUN AS ROOT

tlog() {
    echo $(date "+%Y-%m-%dT%H:%M:%S%:z")'|'"$@"
}

# Optional packages, use "-o" to install via system package manager
optional_common=(vifm xclip enca rclone ffmpeg rsync p7zip html2text)
# Optional packages, need to install in different ways on different OS
optional_spec=(ninja)

tlog "The following packages will be installed:" "${optional_common[@]}" "${optional_spec[@]}"

## Get distribution name
os_name=$(uname)
if [[ $os_name == "Linux" ]]; then
    disv=$(awk '{print $1}' </etc/issue)
elif [[ $os_name == "Darwin" ]]; then
    disv="macOS"
fi

tlog "Detected distribution: $disv"

# Install on ArchLinux
if [[ $disv == "Arch" ]]; then
    installPkg() {
        yay -Syyu $@
    }
    installPkg ninja
elif [[ $disv == "Ubuntu" ]]; then
    sudo apt update
    sudo apt upgrade -y
    installPkg() {
        sudo apt install -y $@
    }
    # ninja
    tlog "Install ninja"
    cd /tmp && wget https://github.com/ninja-build/ninja/releases/download/v1.11.1/ninja-linux.zip
    unzip ninja-linux.zip
    sudo cp ninja /usr/local/bin/ninja
elif [[ $disv == "macOS" ]]; then
    brew update
    brew upgrade
    installPkg() {
        brew install $@
    }
    installPkg ninja
fi

# Install common required and optional packages
installPkg ${optional_common[@]}

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
