#!/usr/bin/env bash

set -eu

read -p "Install nerd font? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "[-] Installing nerd-fonts (may take awhile)"
  git clone https://github.com/ryanoasis/nerd-fonts --depth 1 /tmp/nerd-fonts
  pushd /tmp/nerd-fonts && ./install.sh
  popd
fi

