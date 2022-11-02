#!/usr/bin/env bash

set -eu

if type nvim >/dev/null 2>&1; then
  echo "[-] neovim already installed => skipping"
else
  echo "[-] installing neovim"
  yay -S --noconfirm neovim
fi

