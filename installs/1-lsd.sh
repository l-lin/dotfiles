#!/usr/bin/env bash

set -eu

lsd_version="0.17.0"

if type lsd >/dev/null 2>&1; then
  echo "[-] lsd already exists => skipping"
else
  echo "[-] installing lsd: https://github.com/Peltoche/lsd"
  curl -L -o /tmp/lsd.deb https://github.com/Peltoche/lsd/releases/download/${lsd_version}/lsd_${lsd_version}_amd64.deb
  sudo dpkg -i /tmp/lsd.deb
fi

