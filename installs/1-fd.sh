#!/usr/bin/env bash

set -eu

fd_version="8.0.0"

if type fd >/dev/null 2>&1; then
  echo "[-] fd (> find) already exists => skipping"
else
  echo "[-] installing fd (> find): https://github.com/sharkdp/fd/"
  curl -o /tmp/fd.deb -L https://github.com/sharkdp/fd/releases/download/v${fd_version}/fd_${fd_version}_amd64.deb
  sudo dpkg -i /tmp/fd.deb
fi
