#!/usr/bin/env zsh

set -eu

rust_version="1.64.0"

if type cargo >/dev/null 2>&1; then
  echo "[-] rust already installed => skipping"
else
  echo "[-] installing rust ${rust_version}"
  asdf plugin add rust https://github.com/code-lever/asdf-rust.git
  asdf install rust "${rust_version}"
  asdf global rust "${rust_version}"
fi

