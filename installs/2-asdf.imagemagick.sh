#!/usr/bin/env zsh

set -eu

imagemagick_version="7.0.11-14"

if type convert >/dev/null 2>&1; then
  echo "[-] imagemagick already installed => skipping"
else
  echo "[-] installing imagemagick ${imagemagick_version}"
  asdf plugin-add imagemagick https://github.com/mangalakader/asdf-imagemagick
  asdf install imagemagick "${imagemagick_version}"
  asdf global imagemagick "${imagemagick_version}"
fi

