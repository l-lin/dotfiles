#!/usr/bin/env zsh
#
# pet: simple command-line snippet manager
# src: https://github.com/knqyf263/pet
#

if ! type pet >/dev/null 2>&1; then
  return
fi

function _pet_select() {
    BUFFER=$(pet search --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle redisplay
}

zle -N _pet_select
stty -ixon
bindkey '^s' _pet_select

