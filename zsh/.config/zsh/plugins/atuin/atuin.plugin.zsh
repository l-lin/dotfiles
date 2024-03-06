#!/usr/bin/env zsh
# Copied and adapted from https://github.com/atuinsh/atuin/blob/main/atuin.plugin.zsh.
local FOUND_ATUIN=$+commands[atuin]

if [[ $FOUND_ATUIN -eq 1 ]]; then
  source <(atuin init zsh --disable-up-arrow)
fi
