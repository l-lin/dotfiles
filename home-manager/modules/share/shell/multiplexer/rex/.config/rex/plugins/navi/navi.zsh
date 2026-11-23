#!/usr/bin/env zsh

emulate -L zsh
setopt no_aliases pipe_fail
[[ -n "$REX_BIN_DIR" ]] && export PATH="$REX_BIN_DIR:$PATH"

session_id=$1
block_id=$2
zoomed_block_id=$3

# Rex clears zoom when focus moves to the picker.
trap '
    rex focus -s "$session_id" "$block_id" >/dev/null
    if [[ -n "$zoomed_block_id" ]]; then
        rex zoom -s "$session_id" "$zoomed_block_id" --on >/dev/null
    fi
' EXIT

selected=$(FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} --no-tmux --height=100%" navi --print)
ret=$?
case $ret in
    0) ;;
    1|130) exit 0 ;;
    *) exit "$ret" ;;
esac
[[ -n "$selected" ]] || exit 0

# Use a paste event to preserve line breaks in shells that support bracketed paste.
jq -cn --arg block "$block_id" --arg text "$selected" \
    '{block_id: $block, event: {type: "paste", payload: {text: $text}}}' |
    rex api call -s "$session_id" block.event - >/dev/null
