#!/usr/bin/env bash
# Script that will create the files needed for nix-direnv to work on the current directory:
# - .envrc
# - flake.nix
# src: https://github.com/nix-community/nix-direnv/wiki/Shell-integration

set -eu

if [ ! -e flake.nix ]; then
	nix flake new -t github:nix-community/nix-direnv .
  direnv allow
elif [ ! -e .envrc ]; then
	echo "use flake" >.envrc
	direnv allow
fi
${EDITOR:-vim} flake.nix
