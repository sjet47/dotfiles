#!/bin/bash

set -e

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
    bash
    zsh
    git
    curl
    cc
)

function print_usage() {
    echo "Usage: init.sh [OPTION]"
    echo "Options:"
    echo "  -h | --help    print help"
    echo "  -u | --user    init for user only, default is system wide"
}

function validate_args() {
    while true; do
        case "$1" in
        -h | --help)
            print_usage
            exit 0
            ;;
        -u | --user) ;;
        *)
            if [[ -z $1 ]]; then
                break
            fi
            echo "Unknown option $1"
            print_usage
            exit 1
            ;;
        esac
        shift 1
    done
}

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
    # shellcheck disable=SC2068
    validate_args $@

    check_env

    for step in "${STEPS[@]}"; do
        # shellcheck disable=SC2068
        bash $step $@
    done

    chsh -s /bin/zsh

    zsh
}

# shellcheck disable=SC2068
main $@
