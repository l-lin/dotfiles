#!/usr/bin/env bash

set -eu

if type aws >/dev/null 2>&1; then
  echo "[-] aws-cli already installed => skipping"
else
  echo "[-] installing aws-cli"
  sudo snap install aws-cli --classic
fi

