#!/bin/bash

set -eo pipefail

source steps/common.sh

pkg_list=(
    zsh
    lsd
    bat
    vim
    lolcat
    atuin
    starship
)

function read_os() {
    ## Get distribution name
    local os_name
    os_name=$(uname)
    if [[ $os_name == "Linux" ]]; then
        cat <(awk '{print $1}' </etc/issue)
    elif [[ $os_name == "Darwin" ]]; then
        echo "macOS"
    fi
}

function install_pkgs_arch() {
    yay -Syyu --needed --noconfirm $@
}

function install_pkgs_ubuntu() {
    sudo apt update
    sudo apt upgrade -y
    sudo apt install $@
}

function install_pkgs_macos() {
    brew update
    brew upgrade
    brew install $@
}

function install_pkgs() {
    local disv
    disv=$(read_os)
    info "Detected distribution: $disv" 0 '*'

    case "$disv" in
    Arch)
        install_pkgs_arch ${pkg_list[@]}
        ;;
    Ubuntu)
        install_pkgs_ubuntu ${pkg_list[@]}
        ;;
    macOS)
        install_pkgs_macos ${pkg_list[@]}
        ;;
    *)
        fatal "Unsupported OS: $disv"
        ;;
    esac
}

function main() {
    install_pkgs
}

main
