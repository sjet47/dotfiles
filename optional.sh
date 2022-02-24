#!/bin/bash

LBP=$HOME/.local/bin
ARCH=$(uname -m)

getbin() {
  wget "$1" -O $LBP/$2
  chmod +x $LBP/$2
}

# Install pls
if [[ $arch == "x86_64" ]]
then
	getbin https://github.com/chenjiandongx/pls/releases/download/v0.1.4/pls_darwin_amd64 /pls
	$lbp/pls upgrade
fi

## Download with pip
python -m pip install html2text --user
