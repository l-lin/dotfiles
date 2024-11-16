#!/usr/bin/env zsh
#
# Warp keybinding was removed from wd plugin. Let's bring it back!
# src: https://github.com/mfaerevaag/wd/pull/134
#

if ! type wd fzf >/dev/null 2>&1; then
  return
fi

# Shamelessly copied and adapted from original.
# src: https://github.com/mfaerevaag/wd/blob/f0f47b7197f24eeb34f5481e1e01e41becb61174/wd.sh#L255-L286
custom_wd_browse() {
    if ! command -v fzf >/dev/null; then
        echo "This functionality requires fzf. Please install fzf first."
        return 1
    fi
    local entries=("${(@f)$(sed "s:${HOME}:~:g" "$WD_CONFIG" | awk -F ':' '{print $1 " -> " $2}')}")
    local script_path="${${(%):-%x}:h}"
    local wd_remove_output=$(mktemp "${TMPDIR:-/tmp}/wd.XXXXXXXXXX")
    entries=("All warp points:" "Press enter to select. Press delete to remove" "${entries[@]}")
    local fzf_bind="delete:execute(echo {} | awk -F ' -> ' '{print \$1}' | xargs -I {} "$script_path/wd.sh" rm {} > "$wd_remove_output")+abort"
    # Customize the fzf option.
    local selected_entry=$(printf '%s\n' "${entries[@]}" | fzf --height 30% --no-reverse --header-lines=2 --bind="$fzf_bind")
    if [[ -e $wd_remove_output ]]; then
        cat "$wd_remove_output"
        rm "$wd_remove_output"
    fi
    if [[ -n $selected_entry ]]; then
        local selected_point="${selected_entry%% ->*}"
        selected_point=$(echo "$selected_point" | xargs)
        wd $selected_point
    fi
}

custom_wd_browse_widget() {
  if [[ -e $WD_CONFIG ]]; then
    custom_wd_browse
    saved_buffer=$BUFFER
    saved_cursor=$CURSOR
    BUFFER=
    zle redisplay
    zle accept-line
  fi
}

zle -N custom_wd_browse_widget

bindkey ${FZF_WD_BINDKEY:-'^B'} custom_wd_browse_widget

