#!/usr/bin/env bash

set -eu

gohugo_version="extended_0.80.0"

if type hugo >/dev/null 2>&1; then
  echo "[-] gohugo already installed => skipping"
else
  echo "[-] installing gohugo"
  asdf plugin add gohugo | true
  asdf install gohugo "${gohugo_version}"
  asdf global gohugo "${gohugo_version}"
fi

