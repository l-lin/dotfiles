#!/usr/bin/env zsh

emulate -L zsh
setopt no_aliases pipe_fail
[[ -n "$REX_BIN_DIR" ]] && export PATH="$REX_BIN_DIR:$PATH"

local session=$1 target=$2 zoom=$3
shift 3
# Rex clears zoom when the picker takes focus.
trap 'rex focus -s "$session" "$target" >/dev/null; [[ -z "$zoom" ]] || rex zoom -s "$session" "$zoom" --on >/dev/null' EXIT

local IFS=$' \t\n\r\v\f'
local pane capture line word i
local -a lines words
local -A seen
for pane in "$target" "$@"; do
    capture=$(rex capture -s "$session" -b "$pane" --trim --unwrap | tail -n 100) || continue
    lines=("${(@f)capture}")
    for (( i = $#lines; i > 0; --i )); do
        line=$lines[i]
        for word in ${=line}; do
            if (( ${#word} >= 5 && ! ${+seen[$word]} )); then
                seen[$word]=1
                words+=("$word")
            fi
        done
    done
done
(( $#words )) || exit 0

(( $+functions[__refresh_fzf_default_opts] )) && __refresh_fzf_default_opts
local selected ret
selected=$(printf '%s\n' "${words[@]}" | fzf --no-tmux --height=100% --no-multi \
    --no-select-1 --no-exit-0 --no-print-query --tiebreak=index --expect=alt-y \
    --header='Enter: insert | Alt-Y: copy')
ret=$?
(( ret == 1 || ret == 130 )) && exit 0
(( ret == 0 )) || exit "$ret"

word=${selected#*$'\n'}
[[ -n "$word" && "$word" != *$'\n'* ]] || exit 0
if [[ "$selected" == alt-y$'\n'* ]]; then
    # OSC 52 writes to the client clipboard, not the terminal host clipboard.
    local encoded
    encoded=$(printf '%s' "$word" | base64 | tr -d '\n') || exit 1
    printf '\033]52;c;%s\a' "$encoded"
else
    rex send -s "$session" -b "$target" -- "$word"
fi
