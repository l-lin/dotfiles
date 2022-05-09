#!/usr/bin/env zsh

set -eu

mongosh_version="1.3.1"

if type mongosh >/dev/null 2>&1; then
  echo "[-] mongosh already installed => skipping"
else
  echo "[-] installing mongosh ${mongosh_version}"
  asdf plugin add mongosh | true
  asdf install mongosh "${mongosh_version}"
  asdf global mongosh "${mongosh_version}"
fi

