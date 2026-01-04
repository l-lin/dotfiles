#!/usr/bin/env zsh
#
# Warp keybinding was removed from wd plugin. Let's bring it back!
# src: https://github.com/mfaerevaag/wd/pull/134
#

if ! type wd fzf >/dev/null 2>&1; then
  return
fi

_wd_browse() {
  local entries=("${(@f)$(sed "s:${HOME}:~:g" "${WD_CONFIG:-${HOME}/.warprc}")}")
  local cmd="printf '%s\n' "${entries[@]}" | column -s':' -t | fzf --no-reverse --no-header"

  if [ -n "${TMUX_PANE-}" ]; then
    # Not the best result, as it will display the command sent to the tmux pane, but it does the job.
    tmux popup -x C -y 0 -w 50% -h 50% -E "result=\$(${cmd} | awk '{ print \$1 }') && tmux send-keys \"wd \$result\" Enter"
  fi
}

_wd_browse_widget() {
  LBUFFER="${LBUFFER}$(_wd_browse)"
  local ret=$?
  zle reset-prompt
  return $ret
}

zle -N _wd_browse_widget
# This is Alt+e in my terminal.
# To know what is the keybinding, press ctrl+v, then press your keybinding.
bindkey '^[e' _wd_browse_widget
