#!/usr/bin/env zsh

set -eu

sops_version="3.7.3"

if type sops >/dev/null 2>&1; then
  echo "[-] sops already installed => skipping"
else
  echo "[-] installing sops ${sops_version}"
  asdf plugin-add sops
  asdf install sops "${sops_version}"
  asdf global sops "${sops_version}"
fi

