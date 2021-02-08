#!/usr/bin/env bash

set -eu

if type nvim >/dev/null 2>&1; then
  echo "[-] neovim already installed => skipping"
else
  echo "[-] installing neovim"
  sudo snap install --beta nvim --classic

  echo "[-] set default editor to neovim"
  sudo update-alternatives --install /usr/bin/editor editor /snap/nvim/current/usr/bin/nvim 100
fi

