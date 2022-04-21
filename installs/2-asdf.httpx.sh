#!/usr/bin/env bash

set -eu

httpx_version="0.29.2"

if type httpx >/dev/null 2>&1; then
  echo "[-] httpx already installed => skipping"
else
  echo "[-] installing httpx"
  asdf plugin add httpx https://github.com/l-lin/asdf-httpx | true
  asdf install httpx "${httpx_version}"
  asdf global httpx "${httpx_version}"
fi

