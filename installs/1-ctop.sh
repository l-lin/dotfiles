#!/usr/bin/env bash

set -eu

ctop_version="0.7.7"

if type ctop >/dev/null 2>&1; then
  echo "[-] ctop already exists => skipping"
else
  echo "[-] installing ctop"
  sudo curl -L -o /usr/local/bin/ctop https://github.com/bcicen/ctop/releases/download/v${ctop_version}/ctop-${ctop_version}-linux-amd64
  sudo chmod +x /usr/local/bin/ctop
fi

