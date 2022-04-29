#!/usr/bin/env zsh

set -eu

k3d_version="5.4.1"

if type k3d >/dev/null 2>&1; then
  echo "[-] k3d already installed => skipping"
else
  echo "[-] installing k3d ${k3d_version}"
  asdf plugin add k3d
  asdf install k3d "${k3d_version}"
  asdf global k3d "${k3d_version}"
fi

