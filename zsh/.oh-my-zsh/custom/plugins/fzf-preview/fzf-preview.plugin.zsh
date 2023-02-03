if type fzf >/dev/null 2>&1; then
    function preview() {
        local file
        file=$(ls -t | fzf --preview 'bat --style numbers,changes --color "always" {} | head -500')
        if [[ -f $file ]]; then
            nvim $file
        elif [[ -d $file ]]; then
            cd $file
            preview
            zle reset-prompt
        fi
    }
    zle -N preview
    bindkey '^q' preview
fi
