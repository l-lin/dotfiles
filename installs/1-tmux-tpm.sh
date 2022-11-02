#!/usr/bin/env bash

set -eu

tpm_home="$HOME/.tmux/plugins/tpm"

if [ ! -d "${tpm_home}" ]; then
  echo "[-] installing TMUX plugin manager to ${tpm_home}"
  git clone https://github.com/tmux-plugins/tpm "${tpm_home}"
else
  echo "[-] TMUX plugin manager already installed to ${tpm_home} => skipping"
fi
