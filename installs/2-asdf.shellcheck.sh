#!/usr/bin/env bash

set -eu

if type shellcheck >/dev/null 2>&1; then
  echo "[-] shellcheck already exists => skipping"
else
  asdf plugin add shellcheck | true
  shellcheck_version=$(asdf list all shellcheck | sort -V -r | head -n 1)
  echo "[-] installing shellcheck ${shellcheck_version}: https://www.shellcheck.net/"
  asdf install shellcheck "${shellcheck_version}"
  asdf global shellcheck "${shellcheck_version}"
fi

