#!/usr/bin/env zsh

set -eu

terraform="0.11.14"

if type terraform >/dev/null 2>&1; then
  echo "[-] terraform already installed => skipping"
else
  echo "[-] installing terraform ${terraform}"
  asdf plugin-add terraform https://github.com/asdf-community/asdf-hashicorp.git
  asdf install terraform "${terraform}"
  asdf global terraform "${terraform}"
fi

