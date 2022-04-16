#!/usr/bin/env zsh

set -eu

quarkus="2.8.0.Final"

if type quarkus >/dev/null 2>&1; then
  echo "[-] quarkus already installed => skipping"
else
  echo "[-] installing quarkus ${quarkus}"
  asdf plugin-add quarkus https://github.com/HonoluluHenk/asdf-quarkus.git | true
  asdf install quarkus "${quarkus}"
  asdf global quarkus "${quarkus}"
fi

