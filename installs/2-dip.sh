#!/usr/bin/env bash

set -eu

dip_version="6.1.0"

if type dip >/dev/null 2>&1; then
  echo "[-] dip already exists => skipping"
else
  echo "[-] installing dip: https://github.com/bibendi/dip"
  sudo curl -o /usr/local/bin/dip -L https://github.com/bibendi/dip/releases/download/v${dip_version}/dip-$(uname -s)-$(uname -m)
  sudo chmod +x /usr/local/bin/dip
fi
