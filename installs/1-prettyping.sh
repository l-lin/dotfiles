#!/usr/bin/env bash

set -eu

if type prettyping >/dev/null 2>&1; then
  echo "[-] prettyping already exists => skipping"
else
  echo "[-] installing prettyping: https://github.com/denilsonsa/prettyping"
  sudo curl -L -o /usr/local/bin/prettyping https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping
  sudo chmod +x /usr/local/bin/prettyping
fi

