#!/usr/bin/env bash

set -eu

if type docker >/dev/null 2>&1; then
  echo "[-] docker already installed => skipping"
else
  echo "[-] installing docker"
  yay -S --noconfirm docker
  sudo usermod -aG docker $USER
fi

