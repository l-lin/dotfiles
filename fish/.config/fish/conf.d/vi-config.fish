function set_vi_mode
    # vi mode
    # default keybindings: /usr/share/fish/functions/fish_vi_key_bindings.fish
    fish_vi_key_bindings

    set --global EDITOR nvim

    # set cursor
    set --global fish_cursor_default block
    set --global fish_cursor_insert line
    set --global fish_cursor_replace_one underscore
    set --global fish_cursor_visual block

    # Keybindings
    bind -s -M insert \ce end-of-line
    bind -s -M insert \cp history-search-backward
    bind -s -M insert \cn history-search-forward
end
