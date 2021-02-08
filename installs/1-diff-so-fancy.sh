#!/usr/bin/env bash

set -eu

if type diff-so-fancy >/dev/null 2>&1; then
  echo "[-] diff-so-fancy already exists => skipping"
else
  echo "[-] installing diff-so-fancy: https://github.com/so-fancy/diff-so-fancy"
  sudo curl -L -o /usr/local/bin/diff-so-fancy https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy
  sudo chmod +x /usr/local/bin/diff-so-fancy
fi

