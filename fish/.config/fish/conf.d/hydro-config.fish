# blazing fast prompt: https://github.com/jorgebucaran/hydro
function configure_hydro
    # symbols
    set --global hydro_symbol_git_dirty ' 🚧'
    set --global hydro_symbol_git_ahead 🔺
    set --global hydro_symbol_git_behind 🔻

    # flags
    set --global hydro_multiline true

    # colors
    set --global hydro_color_pwd 7e9cd8
    set --global hydro_color_prompt 6a9589
    set --global hydro_color_git e6c384 --bold
    set --global fish_color_selection 090618 --bold --background=7e9cd8
    set --global fish_color_match 090618 --bold --background=957fb8
    set --global fish_color_error c34043 --bold
end
