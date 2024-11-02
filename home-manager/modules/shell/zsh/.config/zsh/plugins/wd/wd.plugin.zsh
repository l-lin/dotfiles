#!/usr/bin/env zsh
#
# Warp keybinding was removed from wd plugin. Let's bring it back!
# src: https://github.com/mfaerevaag/wd/pull/134
#

if ! type wd fzf >/dev/null 2>&1; then
  return
fi

bindkey ${FZF_WD_BINDKEY:-'^B'} wd_browse_widget

