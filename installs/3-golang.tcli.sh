#!/usr/bin/env bash

set -eu

if type tcli >/dev/null 2>&1; then
  echo "[-] tcli already exists => skipping"
else
  echo "[-] installing tcli: https://github.com/l-lin/tcli"
  go get github.com/l-lin/tcli
  asdf reshim golang
fi

