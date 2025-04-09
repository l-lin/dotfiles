#!/usr/bin/env zsh
#     ____      ____
#    / __/___  / __/
#   / /_/_  / / /_
#  / __/ / /_/ __/
# /_/   /___/_/ key-bindings.zsh
#
# - $FZF_TMUX_OPTS
# - $FZF_CTRL_T_COMMAND
# - $FZF_CTRL_T_OPTS
# - $FZF_CTRL_R_OPTS
# - $FZF_ALT_C_COMMAND
# - $FZF_ALT_C_OPTS
# Copied and adapted to change the following:
# - fzf-file-widget keymap changed to ctrl-g
# - remove fzf-history-widget ctrl-r keymap (replaced by atuin)

[[ -o interactive ]] || return 0

# Key bindings
# ------------

# The code at the top and the bottom of this file is the same as in completion.zsh.
# Refer to that file for explanation.
if 'zmodload' 'zsh/parameter' 2>'/dev/null' && (( ${+options} )); then
  __fzf_key_bindings_options="options=(${(j: :)${(kv)options[@]}})"
else
  () {
    __fzf_key_bindings_options="setopt"
    'local' '__fzf_opt'
    for __fzf_opt in "${(@)${(@f)$(set -o)}%% *}"; do
      if [[ -o "$__fzf_opt" ]]; then
        __fzf_key_bindings_options+=" -o $__fzf_opt"
      else
        __fzf_key_bindings_options+=" +o $__fzf_opt"
      fi
    done
  }
fi

'builtin' 'emulate' 'zsh' && 'builtin' 'setopt' 'no_aliases'

{

__refresh_fzf_default_opts() {
  # Re-source the FZF_DEFAULT_OPTS so that fzf has the latest options & colors.
  [[ -r "${ZDOTDIR:-${HOME}/.config/zsh}/zprofile.d/.zprofile.fzf" ]] && source "${ZDOTDIR:-${HOME}/.config/zsh}/zprofile.d/.zprofile.fzf"
}

__fzfcmd() {
  [ -n "${TMUX_PANE-}" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "${FZF_TMUX_OPTS-}" ]; } &&
    echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

#
# CTRL-G - Paste the selected file path(s) into the command line
#
__fsel() {
  # The env variable is FZF_CTRL_T_COMMAND because it's set by other things,
  # like home-manager.
  local cmd="${FZF_CTRL_T_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type f -print \
    -o -type d -print \
    -o -type l -print 2> /dev/null | cut -b3-"}"
  setopt localoptions pipefail no_aliases 2> /dev/null
  local item
  eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --scheme=path --bind=ctrl-z:ignore ${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-}" $(__fzfcmd) -m "$@" | while read item; do
    echo -n "${(q)item} "
  done
  local ret=$?
  echo
  return $ret
}

fzf-file-widget() {
  __refresh_fzf_default_opts
  LBUFFER="${LBUFFER}$(__fsel)"
  local ret=$?
  zle reset-prompt
  return $ret
}
zle     -N            fzf-file-widget
bindkey -M emacs '^G' fzf-file-widget
bindkey -M vicmd '^G' fzf-file-widget
bindkey -M viins '^G' fzf-file-widget

#
# ALT-C - cd into the selected directory
#
fzf-cd-widget() {
  local cmd="${FZF_ALT_C_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type d -print 2> /dev/null | cut -b3-"}"
  setopt localoptions pipefail no_aliases 2> /dev/null
  local dir="$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --scheme=path --bind=ctrl-z:ignore ${FZF_DEFAULT_OPTS-} ${FZF_ALT_C_OPTS-}" $(__fzfcmd) +m)"
  if [[ -z "$dir" ]]; then
    zle redisplay
    return 0
  fi
  zle push-line # Clear buffer. Auto-restored on next prompt.
  BUFFER="builtin cd -- ${(q)dir}"
  zle accept-line
  local ret=$?
  unset dir # ensure this doesn't end up appearing in prompt expansion
  zle reset-prompt
  return $ret
}
zle     -N             fzf-cd-widget
bindkey -M emacs '\ec' fzf-cd-widget
bindkey -M vicmd '\ec' fzf-cd-widget
bindkey -M viins '\ec' fzf-cd-widget

#
# ALT-F - Grep file content
#
__fsel_grep() {
  local cmd="${FZF_ALT_F_COMMAND:-"rg --column --line-number --no-heading --color=always --smart-case "}"
  setopt localoptions pipefail no_aliases 2> /dev/null

  local selected
  selected=$(eval "$cmd ''" | \
    FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --scheme=path --ansi \
      --disabled --query '' \
      --bind=ctrl-z:ignore \
      --bind 'change:reload:sleep 0.1; $cmd {q} || true' \
      --delimiter : \
      --with-nth 1,2,3 \
      --preview 'bat --color=always {1} --highlight-line {2} 2>/dev/null || cat {1}' \
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
      ${FZF_DEFAULT_OPTS-} ${FZF_ALT_F_OPTS-}" $(__fzfcmd) | \
    awk -F':' '{print $1}')

  # Check if a selection was made
  if [[ -n "$selected" ]]; then
    echo -n "$selected"
    return 0
  fi
  return 1
}

fzf-grep-widget() {
  __refresh_fzf_default_opts
  LBUFFER="${LBUFFER}$(__fsel_grep)"
  local ret=$?
  zle reset-prompt
  return $ret
}
zle     -N            fzf-grep-widget
bindkey -M emacs '\ef' fzf-grep-widget
bindkey -M vicmd '\ef' fzf-grep-widget
bindkey -M viins '\ef' fzf-grep-widget

} always {
  eval $__fzf_key_bindings_options
  'unset' '__fzf_key_bindings_options'
}

