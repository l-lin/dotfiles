#!/usr/bin/env zsh
#
# vi mode
#

# ensure other plugins keybinding are preserved when using zsh-vi-mode
# see https://github.com/jeffreytse/zsh-vi-mode/issues/242
function zvm_after_init() {
  zvm_bindkey viins '^f' _navi_widget
}

# delete word with ctrl+w
# src https://unix.stackexchange.com/a/392199
autoload -U select-word-style
select-word-style bash
export WORDCHARS='.-'

