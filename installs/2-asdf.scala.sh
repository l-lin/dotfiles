#!/usr/bin/env zsh

set -eu

scala_id="2.11.12"

if type scala >/dev/null 2>&1; then
  echo "[-] scala already installed => skipping"
else
  echo "[-] installing scala ${scala_id}"
  asdf plugin add scala
  asdf install scala "${scala_id}"
  asdf global scala "${scala_id}"
fi

