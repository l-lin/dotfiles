#!/usr/bin/env zsh

set -eu

gradle_version="7.4.2"

if type gradle >/dev/null 2>&1; then
  echo "[-] gradle already installed => skipping"
else
  echo "[-] installing gradle ${gradle_version}"
  asdf plugin add gradle
  asdf install gradle "${gradle_version}"
  asdf global gradle "${gradle_version}"
fi

