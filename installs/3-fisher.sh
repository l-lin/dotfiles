#!/usr/bin/env bash

set -eu

if type fisher >/dev/null 2>&1; then
  echo "[-] fisher already exists => skipping"
  fisher update
else
  echo "[-] installing fisher: https://github.com/jorgebucaran/fisher"
  curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish \
    | source \
    && fisher update
fi

