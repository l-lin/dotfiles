#!/usr/bin/env zsh

set -eu

groovy_version="4.0.2"

if type groovy >/dev/null 2>&1; then
  echo "[-] groovy already installed => skipping"
else
  echo "[-] installing groovy ${groovy_version}"
  asdf plugin add groovy
  asdf install groovy "${groovy_version}"
  asdf global groovy "${groovy_version}"
fi

