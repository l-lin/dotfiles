#!/usr/bin/env zsh

set -eu

nodejs_version="15.8.0"

if type node >/dev/null 2>&1; then
  echo "[-] nodejs already installed => skipping"
else
  echo "[-] installing NodeJS"
  asdf plugin add nodejs
  #bash -c '${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring'
  asdf install nodejs "${nodejs_version}"
  asdf global nodejs "${nodejs_version}"
fi

