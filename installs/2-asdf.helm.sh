#!/usr/bin/env zsh

set -eu

helm_version="3.8.1"

if type helm >/dev/null 2>&1; then
  echo "[-] helm already installed => skipping"
else
  echo "[-] installing helm ${helm_version}"
  asdf plugin add helm
  asdf install helm "${helm_version}"
  asdf global helm "${helm_version}"
fi

