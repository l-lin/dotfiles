# add ctrl+n shortcut to search files
zle     -N            fzf-file-widget
bindkey -M emacs '^M' fzf-file-widget
bindkey -M vicmd '^M' fzf-file-widget
bindkey -M viins '^M' fzf-file-widget
