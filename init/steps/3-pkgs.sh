#!/bin/bash

set -e

source "$(dirname $0)/common.sh"

PKG=(
    lsd
    bat
    atuin
    starship
    zoxide
    pv
)

function read_flag_user() {
    while true; do
        case "$1" in
        -u | --user)
            return 0
            ;;
        *)
            if [[ -z $1 ]]; then
                break
            fi
            ;;
        esac
        shift 1
    done
    return 1
}

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

function install_system() {
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
        fatal "unsupported OS: $disv"
        ;;
    esac
}

function install_user() {
    info "install pkgs for user"

    info "installing Cargo" 3 '*'
    # Most tools can be installed with cargo install, so install it first
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env

    info "installing package {lsd, bat, zoxide, pv, starship, atuin} with Cargo " 3 '*'

    cargo install lsd bat zoxide pv starship atuin

    #cargo install cargo-binstall

    ## shellcheck disable=SC2068
    #cargo binstall --strategies crate-meta-data lsd bat zoxide pv

    #info "installing starship " 3 '*'
    ## Install starship
    #curl -sS https://starship.rs/install.sh | sh -s -- -b $HOME/.local/bin -y

    #info "installing atuin " 3 '*'
    ## Install atuin
    #curl --proto '=https' --tlsv1.2 -LsSf https://github.com/atuinsh/atuin/releases/latest/download/atuin-installer.sh | sh

    ok "all pkgs installed"
}

function main() {
    # shellcheck disable=SC2068
    if read_flag_user $@; then
        install_user
    else
        install_system
    fi
}

# shellcheck disable=SC2068
main $@
