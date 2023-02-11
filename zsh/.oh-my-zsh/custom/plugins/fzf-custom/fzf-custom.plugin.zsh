# add ctrl+n shortcut to search files
zle     -N            fzf-file-widget
bindkey -M emacs '^N' fzf-file-widget
bindkey -M vicmd '^N' fzf-file-widget
bindkey -M viins '^N' fzf-file-widget
