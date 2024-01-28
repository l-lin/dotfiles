if status is-interactive
    # do not display welcome message
    set fish_greeting

    set_vi_mode
    add_abbreviations

    configure_prompt
    configure_fzf
    configure_pet
    configure_navi
end
