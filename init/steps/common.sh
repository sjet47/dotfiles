#!/bin/bash

tlog() {
    echo -e "$(date "+%Y-%m-%dT%H:%M:%S%:z")" "$@"
}

function info() {
    prompt=${3:--}
    tlog "$(printf %${2:-0}s)[\e[34m${prompt}\e[0m] $1"
}

function ok() {
    prompt=${3:-*}
    tlog "$(printf %${2:-0}s)[\e[32m${prompt}\e[0m] $1"
}

function warn() {
    prompt=${3:-!}
    tlog "$(printf %${2:-0}s)[\e[33m${prompt}\e[0m] $1"
}

function fatal() {
    prompt=${3:-FATAL}
    tlog "$(printf %${2:-0}s)[\e[31m${prompt}\e[0m] $1"
    exit 1
}
