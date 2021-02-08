#!/usr/bin/env bash

set -eu

if type docker >/dev/null 2>&1; then
  echo "[-] docker already installed => skipping"
else
  echo "[-] installing docker"
  curl -fsSL https://get.docker.com/ | sh
  docker --version
  sudo usermod -aG docker $USER
fi

