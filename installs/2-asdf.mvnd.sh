#!/usr/bin/env zsh

set -eu

mvnd_version="3.6.3"

if type mvn >/dev/null 2>&1; then
  echo "[-] mvnd already installed => skipping"
else
  echo "[-] installing mvnd ${mvnd_version}"
  asdf plugin-add mvnd https://github.com/joschi/asdf-mvnd
  asdf install mvnd "${mvnd_version}"
  asdf global mvnd "${mvnd_version}"
fi

