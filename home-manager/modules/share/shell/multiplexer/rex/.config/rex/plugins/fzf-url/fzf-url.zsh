#!/usr/bin/env zsh
# Rex blocks -> last 100 lines per block -> unique HTTP(S) URLs -> fzf
#                                                                  |-- Enter -> host browser
#                                                                  `-- Alt-Y -> client clipboard

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

local block capture line_index urls
local -a lines
urls=$(
    # fzf uses this order to break ties: source block first, newest lines first.
    for block in "$source_block" "$@"; do
        capture=$(rex capture -s "$session" -b "$block" --trim --unwrap | tail -n 100) || continue
        lines=("${(@f)capture}")
        for (( line_index = $#lines; line_index > 0; --line_index )); do
            print -r -- "$lines[line_index]"
        done
    done | awk '
        function extra_close(url, left, right,     copy, closes) {
            copy = url
            closes = gsub(right, "", copy)
            return closes > gsub(left, "", copy)
        }

        # Keep balanced delimiters, such as parentheses in a Wikipedia URL.
        function trim_url(url) {
            while (sub(/[.,;:!?\047]+$/, "", url) ||
                   (url ~ /[)]$/ && extra_close(url, "[(]", "[)]") && sub(/[)]$/, "", url)) ||
                   (url ~ /[]]$/ && extra_close(url, "[[]", "[]]") && sub(/[]]$/, "", url)) ||
                   (url ~ /[}]$/ && extra_close(url, "[{]", "[}]") && sub(/[}]$/, "", url))) {}
            return url
        }

        {
            while (match($0, /[Hh][Tt][Tt][Pp][Ss]?:\/\/[^[:space:][:cntrl:]<>"`]+/)) {
                url = trim_url(substr($0, RSTART, RLENGTH))
                if (url ~ /:\/\/[^\/?#]/ && !seen[url]++) print url
                $0 = substr($0, RSTART + RLENGTH)
            }
        }
    '
) || exit 1
[[ -n "$urls" ]] || exit 0

(( $+functions[__refresh_fzf_default_opts] )) && __refresh_fzf_default_opts
local selection picker_status
selection=$(print -r -- "$urls" | fzf --no-tmux --height=100% --no-multi --no-preview \
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
