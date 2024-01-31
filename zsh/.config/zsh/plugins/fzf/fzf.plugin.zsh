#!/usr/bin/env zsh

[[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh

if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh

  zle     -N            fzf-file-widget
  bindkey -M emacs '^G' fzf-file-widget
  bindkey -M vicmd '^G' fzf-file-widget
  bindkey -M viins '^G' fzf-file-widget
fi

