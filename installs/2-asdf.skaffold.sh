#!/usr/bin/env zsh

set -eu

skaffold_version="1.38.0"

if type skaffold >/dev/null 2>&1; then
  echo "[-] skaffold already installed => skipping"
else
  echo "[-] installing skaffold ${skaffold_version}"
  asdf plugin add skaffold
  asdf install skaffold "${skaffold_version}"
  asdf global skaffold "${skaffold_version}"
fi

