#!/usr/bin/env zsh
#
# Open an fzf picker and send the selected paths to the source Rex block.
#

emulate -L zsh
setopt no_aliases
[[ -n "$REX_BIN_DIR" ]] && export PATH="$REX_BIN_DIR:$PATH"
# Rex clears zoom when focus moves to the picker.
# Restore focus before restoring zoom.
trap '
    rex focus -s "$1" "$2" >/dev/null
    [[ -n "$3" ]] && rex zoom -s "$1" "$3" --on >/dev/null
' EXIT

(( $+functions[__refresh_fzf_default_opts] )) && __refresh_fzf_default_opts

local mode="${4-}" selected
local -a fzf_args=(--no-tmux --height=100% --scheme=path --bind=ctrl-z:ignore)

# grep:  query -> rg -> fzf -> path:line:column:match
# files:          fd -> fzf -> path<NUL>path<NUL>...
if [[ "$mode" == grep ]]; then
    # Let rg interpret the query. A query with no matches is not an error.
    local rg_command="${FZF_ALT_F_COMMAND:-rg --column --line-number --no-heading --color=always --smart-case --}"
    selected=$(FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_ALT_F_OPTS-}" \
        fzf "${fzf_args[@]}" --ansi --disabled --query '' +m \
        --bind "start:reload:$rg_command '' || true" \
        --bind "change:reload:sleep 0.1; $rg_command {q} || true" \
        --delimiter : --with-nth 1,2,3 \
        --preview 'bat --color=always --highlight-line {2} -- {1} 2>/dev/null || cat -- {1}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' </dev/null)
else
    selected=$(FZF_DEFAULT_COMMAND="${FZF_CTRL_T_COMMAND:-fd --type f --hidden --exclude .git}" \
        FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-}" \
        fzf "${fzf_args[@]}" --multi --print0)
fi
local exit_code=$?
case $exit_code in
    0) ;;
    1|130) exit 0 ;;  # No match or cancellation. Close without sending input.
    *) exit "$exit_code" ;;
esac

# Use the line and column in the picker only. Send the path to Rex.
[[ "$mode" == grep ]] && selected="${selected%%:*}"

# Split on NUL, not on spaces. Quote each path for the source shell.
local item input=""
selected="${selected%$'\0'}"
for item in "${(@0)selected}"; do
    input+="${(q)item} "
done
[[ -n "$input" ]] && rex send -s "$1" -b "$2" -- "$input"
