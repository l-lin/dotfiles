#!/usr/bin/env zsh
# Unique HTTP(S) URLs -> fzf
#                        |-- Enter -> host browser
#                        `-- Alt-Y -> client clipboard

emulate -L zsh
setopt no_aliases pipe_fail
[[ -n "$REX_BIN_DIR" ]] && export PATH="$REX_BIN_DIR:$PATH"

local session=$1 source_block=$2 zoomed_block=$3
shift 3

# Rex clears zoom when the picker takes focus.
trap '
    rex focus -s "$session" "$source_block" >/dev/null
    if [[ -n "$zoomed_block" ]]; then
        rex zoom -s "$session" "$zoomed_block" --on >/dev/null
    fi
' EXIT

(( $# > 0 )) || exit 0

(( $+functions[__refresh_fzf_default_opts] )) && __refresh_fzf_default_opts
local selection picker_status
selection=$(print -rl -- "$@" | fzf --no-tmux --height=100% --no-multi --no-preview \
    --no-select-1 --no-exit-0 --no-print-query --tiebreak=index --expect=alt-y \
    --header='Enter: open | Alt-Y: copy')
picker_status=$?
case $picker_status in
    0) ;;
    1|130) exit 0 ;;
    *) exit "$picker_status" ;;
esac

# --expect prints the key on the first line. This line is empty for Enter.
local key url
[[ "$selection" == *$'\n'* ]] || exit 0
key=${selection%%$'\n'*}
url=${selection#*$'\n'}
[[ "$url" == [Hh][Tt][Tt][Pp]([Ss]|)://?* && "$url" != *$'\n'* ]] || exit 0

case $key in
    alt-y)
        # OSC 52 writes to the Rex client clipboard, not the host clipboard.
        local encoded
        encoded=$(printf '%s' "$url" | base64 | tr -d '\n') || exit 1
        printf '\033]52;c;%s\a' "$encoded"
        ;;
    '')
        if [[ "$OSTYPE" == darwin* ]]; then
            command open "$url"
        else
            command xdg-open "$url"
        fi
        ;;
esac
