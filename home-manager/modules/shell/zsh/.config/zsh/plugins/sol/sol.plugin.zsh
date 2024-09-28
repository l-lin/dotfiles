#!/usr/bin/env zsh
#
# A de-minifier (formatter, exploder, beautifier) for shell one-liners.
# src: https://github.com/noperator/sol
#

if ! type sol >/dev/null 2>&1; then
  return
fi

function _sol_explode() {
  local current_line="${BUFFER}"
  BUFFER=$(sol -p -c -b -r -a -s -jqobj -jqarr -jqop comma <<< "$current_line")
  CURSOR=$#BUFFER
}

zle -N _sol_explode
bindkey '^x' _sol_explode

