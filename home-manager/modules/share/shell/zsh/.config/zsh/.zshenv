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
# ZSH folder descriptions:
# - completions/: contains the completion scripts used when using <tab> to auto-complete commands
#   - a `zcompdump` file is used as cache to speed up running `compinit`
#   - see: https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Completion-System
#   - call `refresh-zsh-completions` if you add new custom completion scripts
# - conf.d/: contains configuration files
# - functions/: contains shell functions
# - plugins/: contains custom plugins
#   - call `refresh-zsh-antidote-plugins` if you add/remove plugins
# - zprofile.d/: env variables to source in login shells (e.g. `.zprofile.work`)
#
# order of operations: .zshenv -> .zprofile -> .zshrc -> .zlogin -> .zlogout
# src: https://apple.stackexchange.com/a/388623
#
# To benchmark your zsh startup, you can use the following:
# - zsh native zprof: zsh -c "zmodload zsh/zprof; source ~/.config/zsh/.zshrc; zprof"
# - custom function: `timesh`
# - more advance tool https://github.com/romkatv/zsh-bench: `zsh-bench`
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
