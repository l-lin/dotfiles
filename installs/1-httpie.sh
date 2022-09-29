#!/usr/bin/env bash

set -eu

if type http >/dev/null 2>&1; then
  echo "[-] httpie already installed => skipping"
else
  echo "[-] installing httpie"
  sudo snap install httpie
fi

