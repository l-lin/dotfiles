#!/usr/bin/env zsh

set -eu

go_version="1.19.1"

if type go >/dev/null 2>&1; then
  echo "[-] go already installed => skipping"
else
  echo "[-] installing go ${go_version}"
  asdf plugin add golang
  asdf install golang "${go_version}"
  asdf global golang "${go_version}"
fi

