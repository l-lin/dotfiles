#!/usr/bin/env zsh

set -eu

caddy_version="2.4.3"

if type caddy >/dev/null 2>&1; then
  echo "[-] caddy already installed => skipping"
else
  echo "[-] installing caddy ${caddy_version}"
  #asdf plugin add caddy
  asdf install caddy "${caddy_version}"
  asdf global caddy "${caddy_version}"
fi

