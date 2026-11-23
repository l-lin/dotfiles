#!/usr/bin/env zsh
#
# Open a fzf picker to select a wd entry and send the command to the original shell.
#

emulate -L zsh
setopt no_aliases
[[ -n "$REX_BIN_DIR" ]] && export PATH="$REX_BIN_DIR:$PATH"
# Rex clears zoom when focus moves to the picker.
trap 'rex focus -s "$1" "$2" >/dev/null; [[ -n "$4" ]] && rex zoom -s "$1" "$4" --on >/dev/null' EXIT

(( $+functions[__refresh_fzf_default_opts] )) && __refresh_fzf_default_opts
local selected ret input config="${WD_CONFIG:-${HOME}/.warprc}"
if [[ ! -r "$config" ]]; then
    print -u2 -r -- "Cannot read wd config: $config"
    exit 2
fi
# Keep the original name separate from the aligned display text.
selected=$(awk -F: '
    {
        names[NR] = $1
        paths[NR] = substr($0, index($0, ":") + 1)
        if (length($1) > width) width = length($1)
    }
    END {
        for (i = 1; i <= NR; i++)
            printf "%s:%-*s  %s\n", names[i], width, names[i], paths[i]
    }
' "$config" | fzf --no-tmux --height=100% --no-multi --no-reverse --no-header \
    --delimiter=: --with-nth=2.. --prompt='󰍉 ' --bind=ctrl-z:ignore)
ret=$?
# Cancellation must close the layer without sending input.
(( ret == 1 || ret == 130 )) && exit 0
(( ret == 0 )) || exit "$ret"
selected="${selected%%:*}"
[[ -n "$selected" ]] || exit 0

# Run wd in the original shell. Rename the tab only if wd succeeds.
input="wd ${(q)selected} && ${(q)commands[rex]} window rename -s ${(q)1} -- ${(q)3} ${(q)selected}"
# Discard pending input so Enter cannot execute an unfinished command.
rex send-key -s "$1" -b "$2" ctrl+c &&
    rex send -s "$1" -b "$2" -- "$input" && rex send-key -s "$1" -b "$2" enter
