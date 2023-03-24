# add ctrl+h shortcut to search files
zle     -N            fzf-file-widget
bindkey -M emacs '^G' fzf-file-widget
bindkey -M vicmd '^G' fzf-file-widget
bindkey -M viins '^G' fzf-file-widget
