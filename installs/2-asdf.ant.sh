#!/usr/bin/env zsh

set -eu

ant_version="1.10.9"

if type ant >/dev/null 2>&1; then
  echo "[-] ant already installed => skipping"
else
  echo "[-] installing ant ${ant_version}"
  asdf plugin add ant
  asdf install ant "${ant_version}"
  asdf global ant "${ant_version}"
fi

