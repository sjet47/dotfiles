#!/bin/bash

set -eo pipefail

init_dir=$(dirname $0)

steps=(
    "$init_dir/steps/1-layout.sh"
    "$init_dir/steps/2-shell.sh"
    "$init_dir/steps/3-pkgs.sh"
)

function main() {
    for step in "${steps[@]}"; do
        sh $step
    done

    chsh -s /bin/zsh

    zsh
}

main
