#!/usr/bin/env zsh

set -eu

checkov_version="2.2.211"

if type checkov >/dev/null 2>&1; then
  echo "[-] checkov already exists => skipping"
else
  echo "[-] installing checkov: https://github.com/bosmak/asdf-checkov"
  asdf plugin add checkov | true
  asdf install checkov "${checkov_version}"
  asdf global checkov "${checkov_version}"
fi

