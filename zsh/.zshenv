#
# Heavily inspired from https://github.com/mattmc3/zdotdir
#
# ZSH file descriptions:
# - zshenv: always sourced
# - zprofile: for login shells
# - zshrc: for interactive shells
# - zlogin: sourced on the start of the login
# - zlogout: used to clear and reset the terminal, called when exiting
#
# order of operations: .zshenv -> .zprofile -> .zshrc -> .zlogin -> .zlogout
# src: https://apple.stackexchange.com/a/388623
#

# skip system wide compinit, let ourself do it
skip_global_compinit=1

export ZDOTDIR=~/.config/zsh
[[ -f $ZDOTDIR/.zshenv ]] && . $ZDOTDIR/.zshenv

