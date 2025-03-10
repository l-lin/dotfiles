#!/usr/bin/env bash

set -e

# No need to execute this pre-commit if not in dotfiles project.
if [ "$(pwd)" != "${XDG_CONFIG_HOME:-${HOME}/.config}/dotfiles" ]; then
  exit 0
fi

if ! type deadnix &>/dev/null; then
  # nixfmt is annoying to install outside of nix, so don't lock ourselves out of tweaking things
  echo -e "\033[1;30;43m W \033[0m Skipping scanning step, 'deadnix' not found."
  exit 0
fi

deadnix --fail --exclude nixos/hardware-configuration.nix

