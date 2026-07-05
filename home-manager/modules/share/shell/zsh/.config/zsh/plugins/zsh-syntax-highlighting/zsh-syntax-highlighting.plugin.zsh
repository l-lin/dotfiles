#!/usr/bin/env zsh
#
# Configure zsh-syntax-highlighting
#

if [[ -v ZSH_HIGHLIGHT_HIGHLIGHTERS ]]; then
  ZSH_HIGHLIGHT_HIGHLIGHTERS+=(main brackets pattern)
else
  ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
fi
