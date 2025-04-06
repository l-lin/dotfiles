#!/usr/bin/env zsh
#
# Interactive cheatsheet tool.
# Updated the script to not perform any replacement (not using it),
# and use Tmux popup instead.
# src: https://github.com/denisidoro/navi/
#

[[ -o interactive ]] || return 0

if ! type navi >/dev/null 2>&1; then
  return
fi

_navi_cmd() {
  [ -n "${TMUX_PANE-}" ] &&
    echo "tmux popup -w ${NAVI_TMUX_WIDTH:-90%} -h ${NAVI_TMUX_HEIGHT:-90%} -E "
}

_navi_sel() {
  local cmd="navi --print | perl -pe 'chomp if eof' | tmux load-buffer -b tmp - ; tmux paste-buffer -p -b tmp -d"

  eval "$(_navi_cmd) \"$cmd\""
}

_navi_widget() {
  LBUFFER="${LBUFFER}$(_navi_sel)"
  local ret=$?
  zle reset-prompt
  return $ret
}

zle -N _navi_widget
bindkey '^f' _navi_widget

