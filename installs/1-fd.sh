#!/usr/bin/env bash

set -eu

fd_version="8.5.0"

if type fd >/dev/null 2>&1; then
  echo "[-] fd (> find) already exists => skipping"
else
  echo "[-] installing fd (> find): https://github.com/sharkdp/fd/"
  yay -S --noconfirm fd
fi
