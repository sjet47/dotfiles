#!/bin/bash

set -eo pipefail

init_dir=$(dirname $0)

source "$init_dir/steps/common.sh"

STEPS=(
    "$init_dir/steps/1-layout.sh"
    "$init_dir/steps/2-shell.sh"
    "$init_dir/steps/3-pkgs.sh"
)

VAR=(
    HOME
)

BIN=(
    zsh
    git
    curl
)

function check_env() {
    for __var__ in "${VAR[@]}"; do
        if [[ -z ${!__var__} ]]; then
            fatal "env $__var__ is not set"
        fi
    done
    for __bin__ in "${BIN[@]}"; do
        if ! command -v $__bin__ &>/dev/null; then
            fatal "$__bin__ is not in PATH"
        fi
    done
}

function main() {
    check_env
    for step in "${STEPS[@]}"; do
        sh $step
    done

    chsh -s /bin/zsh

    zsh
}

main
