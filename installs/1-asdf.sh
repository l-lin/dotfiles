#!/usr/bin/env bash

set -eu

asdf_version="0.8.0"
asdf_home="$HOME/.asdf"

if [ ! -d "${asdf_home}" ]; then
  echo "[-] installing asdf"
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch "v${asdf_version}"
else
  echo "[-] asdf already installed => skipping"
fi

