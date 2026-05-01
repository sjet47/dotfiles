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

function install_pkgs_arch() {
    info "Installing packages with yay" 3 '*'
    # shellcheck disable=SC2068
    yay -Syyu --needed --noconfirm $@
}

function install_pkgs_macos() {
    info "Installing packages with brew" 3 '*'
    brew update
    brew upgrade
    # shellcheck disable=SC2068
    brew install $@
}

function install_system() {
    local os_type
    os_type=$(detect_os)

    case "$os_type" in
    macos)
        info "Detected: macOS" 0 '*'
        # shellcheck disable=SC2068
        install_pkgs_macos ${PKG[@]}
        ;;
    arch)
        info "Detected: Arch Linux" 0 '*'
        # shellcheck disable=SC2068
        install_pkgs_arch ${PKG[@]}
        ;;
    other)
        info "Unsupported OS detected, falling back to --user mode" 0 '!'
        install_user
        ;;
    esac
}

function install_user() {
    info "Installing packages for user (local environment)" 0 '*'

    # Install Rust toolchain first as it's needed for cargo
    if ! command -v cargo &>/dev/null; then
        info "Installing Rust toolchain with rustup" 3 '*'
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y --no-modify-path
        # shellcheck disable=SC1091
        source "$HOME/.cargo/env"
    else
        info "Cargo already installed, skipping rustup" 3
    fi

    # Install packages using cargo
    info "Installing packages {lsd, bat, zoxide, pv, starship, atuin} with Cargo" 3 '*'
    # shellcheck disable=SC2068
    cargo install lsd bat zoxide pv starship atuin

    ok "All packages installed for user"
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
