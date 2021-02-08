#!/usr/bin/env bash

set -eu

fzf_version="0.25.1"

if type fzf >/dev/null 2>&1; then
  echo "[-] fuzzy finder already exists => skipping"
else
  echo "[-] installing fuzzy finder ${fzf_version}"
  asdf plugin add fzf
  asdf install fzf "${fzf_version}"
  asdf global fzf "${fzf_version}"
fi

