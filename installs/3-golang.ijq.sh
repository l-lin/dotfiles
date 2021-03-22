#!/usr/bin/env bash

set -eu

if type ijq >/dev/null 2>&1; then
  echo "[-] ijq already exists => skipping"
else
  echo "[-] installing ijq: https://git.sr.ht/~gpanders/ijq"
  go get git.sr.ht/~gpanders/ijq
  asdf reshim golang
fi

