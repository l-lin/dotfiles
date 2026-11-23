#!/usr/bin/env zsh
#
# Open a file picker using fzf and send the selected files to the current Rex session.
#

emulate -L zsh
setopt no_aliases
[[ -n "$REX_BIN_DIR" ]] && export PATH="$REX_BIN_DIR:$PATH"
# Rex clears zoom when focus moves to the picker.
trap 'rex focus -s "$1" "$2" >/dev/null; [[ -n "$3" ]] && rex zoom -s "$1" "$3" --on >/dev/null' EXIT

(( $+functions[__refresh_fzf_default_opts] )) && __refresh_fzf_default_opts
local selected item input="" ret
selected=$(FZF_DEFAULT_COMMAND="${FZF_CTRL_T_COMMAND:-fd --type f --hidden --exclude .git}" \
    FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-}" \
    fzf --no-tmux --height=100% --scheme=path --bind=ctrl-z:ignore --multi --print0)
ret=$?
# Cancellation must close the layer without sending input.
(( ret == 1 || ret == 130 )) && exit 0
(( ret == 0 )) || exit "$ret"

# NUL separators preserve spaces and shell quoting prevents command execution.
selected="${selected%$'\0'}"
for item in "${(@0)selected}"; do
    input+="${(q)item} "
done
[[ -n "$input" ]] && rex send -s "$1" -b "$2" -- "$input"
