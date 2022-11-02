#!/usr/bin/env bash

set -eu

lsd_version="0.17.0"

if type lsd >/dev/null 2>&1; then
  echo "[-] lsd already exists => skipping"
else
  echo "[-] installing lsd: https://github.com/Peltoche/lsd"
  yay -S --noconfirm lsd
fi

