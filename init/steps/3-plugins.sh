#!/bin/bash

set -eo pipefail

source steps/common.sh

OMZ="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$OMZ/custom"

function clone_repo() {
    local name=$1
    local repo_url=$2
    local path=$3
    info "Cloning $name" 3 '*'
    git clone $repo_url $path
}

function clone_repos() {
    info "install zsh plugins"

    # oh-my-zsh
    clone_repo "oh-my-zsh" "https://github.com/ohmyzsh/ohmyzsh.git" "$ZSH"

    # zsh-completions
    clone_repo "zsh-completions" "https://github.com/zsh-users/zsh-completions" "$ZSH_CUSTOM/plugins/zsh-completions"

    # zsh-syntax-highlighting
    clone_repo "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

    # zsh-autosuggestions
    clone_repo "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions" "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

    ok "zsh plugins installed"
}

function main() {
    clone_repos
}

main
