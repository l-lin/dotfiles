# add ctrl+h shortcut to search files
zle     -N            fzf-file-widget
bindkey -M emacs '^H' fzf-file-widget
bindkey -M vicmd '^H' fzf-file-widget
bindkey -M viins '^H' fzf-file-widget
