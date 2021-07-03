#!/usr/bin/env bash

set -eu

if type bw >/dev/null 2>&1; then
  echo "[-] bw already installed => skipping"
else
  echo "[-] installing bw"
  sudo snap install bw
fi

