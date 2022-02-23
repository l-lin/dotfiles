#!/usr/bin/env zsh

set -eu

kubectl="1.23.4"

if type kubectl >/dev/null 2>&1; then
  echo "[-] kubectl already installed => skipping"
else
  echo "[-] installing kubectl ${kubectl}"
  asdf plugin add kubectl
  asdf install kubectl "${kubectl}"
  asdf global kubectl "${kubectl}"
fi

