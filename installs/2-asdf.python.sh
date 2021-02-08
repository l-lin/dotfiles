#!/usr/bin/env zsh

set -eu

python2_version="2.7.14"
python3_version="3.9.1"

if type python >/dev/null 2>&1; then
  echo "[-] python already installed => skipping"
else
  echo "[-] installing python ${python2_version} & ${python3_version}"
  asdf plugin add python
  asdf install python "${python2_version}"
  asdf install python "${python3_version}"
  asdf global python "${python3_version} ${python2_version}"
fi

