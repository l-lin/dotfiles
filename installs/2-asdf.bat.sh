#!/usr/bin/env zsh

set -eu

bat_version="0.17.1"

if type bat >/dev/null 2>&1; then
  echo "[-] bat already exists => skipping"
else
  echo "[-] installing bat: https://github.com/sharkdp/bat"
  asdf plugin add bat
  asdf install bat "${bat_version}"
  asdf global bat "${bat_version}"
fi

