#!/usr/bin/env zsh
#
# Edit command line in full screen editor.
# src: https://unix.stackexchange.com/questions/6620/ddg#34251
#

autoload -z edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line
