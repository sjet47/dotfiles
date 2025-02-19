#!/bin/bash

set -eo pipefail

source "$(dirname $0)/common.sh"

PKG=(
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
    # shellcheck disable=SC2068
    yay -Syyu --needed --noconfirm $@
}

function install_pkgs_ubuntu() {
    sudo apt update
    sudo apt upgrade -y
    # shellcheck disable=SC2068
    sudo apt install $@
}

function install_pkgs_macos() {
    brew update
    brew upgrade
    # shellcheck disable=SC2068
    brew install $@
}

function install_pkgs() {
    local disv
    disv=$(read_os)
    info "Detected distribution: $disv" 0 '*'

    case "$disv" in
    Arch)
        # shellcheck disable=SC2068
        install_pkgs_arch ${PKG[@]}
        ;;
    Ubuntu)
        # shellcheck disable=SC2068
        install_pkgs_ubuntu ${PKG[@]}
        ;;
    macOS)
        # shellcheck disable=SC2068
        install_pkgs_macos ${PKG[@]}
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
