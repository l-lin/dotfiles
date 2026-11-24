#!/usr/bin/env zsh
#
# Rex blocks -> last 100 lines per block -> unique words -> fzf
#                                                           |-- Enter -> source block
#                                                           `-- Alt-Y -> client clipboard
#

emulate -L zsh
setopt no_aliases pipe_fail
[[ -n "$REX_BIN_DIR" ]] && export PATH="$REX_BIN_DIR:$PATH"

local session=$1 source_block=$2 zoomed_block=$3
shift 3

# Focus the source block before you restore zoom. The picker clears zoom when it takes focus.
trap '
    rex focus -s "$session" "$source_block" >/dev/null
    if [[ -n "$zoomed_block" ]]; then
        rex zoom -s "$session" "$zoomed_block" --on >/dev/null
    fi
' EXIT

local IFS=$' \t\n\r\v\f'
local block capture line word line_index
local -a lines words
local -A seen

# Start with the source block. Read the newest lines first in each block.
# fzf uses this order to break ties.
for block in "$source_block" "$@"; do
    capture=$(rex capture -s "$session" -b "$block" --trim --unwrap | tail -n 100) || continue
    lines=("${(@f)capture}")
    for (( line_index = $#lines; line_index > 0; --line_index )); do
        line=$lines[line_index]
        for word in ${=line}; do
            (( ${#word} >= 5 && ! ${+seen[$word]} )) || continue
            seen[$word]=1
            words+=("$word")
        done
    done
done
(( $#words )) || exit 0

(( $+functions[__refresh_fzf_default_opts] )) && __refresh_fzf_default_opts
local selection picker_status
selection=$(printf '%s\n' "${words[@]}" | fzf --no-tmux --height=100% --no-multi \
    --no-select-1 --no-exit-0 --no-print-query --tiebreak=index --expect=alt-y \
    --header='Enter: insert | Alt-Y: copy')
picker_status=$?
case $picker_status in
    0) ;;
    1|130) exit 0 ;; # No match or cancelled.
    *) exit "$picker_status" ;;
esac

# --expect prints the key on the first line. This line is empty for Enter.
word=${selection#*$'\n'}
[[ -n "$word" && "$word" != *$'\n'* ]] || exit 0
if [[ "$selection" == alt-y$'\n'* ]]; then
    # OSC 52 writes to the client clipboard, not the terminal host clipboard.
    local encoded
    encoded=$(printf '%s' "$word" | base64 | tr -d '\n') || exit 1
    printf '\033]52;c;%s\a' "$encoded"
else
    rex send -s "$session" -b "$source_block" -- "$word"
fi
