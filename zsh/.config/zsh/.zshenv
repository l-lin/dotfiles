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

#
# .zshenv - Zsh environment file, loaded always.
#

# skip system wide compinit, let ourself do it
skip_global_compinit=1

export ZDOTDIR="${HOME}/.config/zsh"

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ! -o LOGIN && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

# vim: ft=zsh
