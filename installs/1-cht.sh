#!/usr/bin/env bash

set -eu

if type cht.sh >/dev/null 2>&1; then
  echo "[-] cht.sh already exists => skipping"
else
  echo "[-] installing cht.sh: https://github.com/chubin/cheat.sh"
  sudo curl -o /usr/local/bin/cht.sh https://cht.sh/:cht.sh
  sudo chmod +x /usr/local/bin/cht.sh
  curl https://cheat.sh/:zsh > "$HOME/.zsh/completion/_cht"
fi

