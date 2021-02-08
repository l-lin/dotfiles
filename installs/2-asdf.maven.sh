#!/usr/bin/env zsh

set -eu

maven_version="3.6.3"

if type mvn >/dev/null 2>&1; then
  echo "[-] maven already installed => skipping"
else
  echo "[-] installing maven ${maven_version}"
  asdf plugin add maven
  asdf install maven "${maven_version}"
  asdf global maven "${maven_version}"
fi

