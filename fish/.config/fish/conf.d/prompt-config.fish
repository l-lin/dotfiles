function configure_prompt
    configure_pure_prompt
end

# pure prompt: https://pure-fish.github.io/pure/
function configure_pure_prompt
    # time
    set --global pure_show_system_time true
    set --global pure_show_subsecond_command_duration true
    set --global pure_threshold_command_duration 1

    # git
    set --universal pure_symbol_git_dirty ' 🚧'
    set --universal pure_symbol_git_stash 🧩
    set --universal pure_symbol_git_unpushed_commits 🔺
    set --universal pure_symbol_git_unpulled_commits 🔻
    set --global async_prompt_functions _pure_prompt_git

    # colors
    set --universal pure_color_current_directory brblue
    set --universal pure_color_git_branch bryellow
    set --universal pure_color_prompt_on_success brgreen
end

# blazing fast prompt: https://github.com/jorgebucaran/hydro
function configure_hydro_prompt
    # symbols
    set --global hydro_symbol_git_dirty ' 🚧'
    set --global hydro_symbol_git_ahead 🔺
    set --global hydro_symbol_git_behind 🔻

    # flags
    set --global hydro_multiline true

    # colors
    set --global hydro_color_pwd blue
    set --global hydro_color_prompt brgreen
    set --global hydro_color_git bryellow --bold
    set --global fish_color_selection brgreen --bold --background=7e9cd8
    set --global fish_color_match 090618 --bold --background=957fb8
    set --global fish_color_error brred --bold
end

