#!/usr/bin/env bash

set -eu

if type fac >/dev/null 2>&1; then
  echo "[-] fac already exists => skipping"
else
  echo "[-] installing fac: https://github.com/mkchoi212/fac"
  go get github.com/mkchoi212/fac
  asdf reshim golang
fi

