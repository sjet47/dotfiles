#!/bin/bash

set -eo pipefail

steps=(
    steps/1-layout.sh
    steps/2-basepkg.sh
    steps/3-plugins.sh
)

function main() {
    for step in "${steps[@]}"; do
        sh $step
    done

    chsh -s /bin/zsh

    zsh
}

main
