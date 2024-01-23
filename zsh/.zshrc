# If not running interactively, do not do anything
[[ $- != *i* ]] && return
[[ -z "$TMUX" ]] && exec tmux -2 -u

# uncomment the following to benchmark your shell
# start a new session, and call `zprof`
#zmodload zsh/zprof

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
export ZSH_CUSTOM=$ZSH/custom

# Set name of the theme to load (located in ~/.oh-my-zsh/themes/ and ~/.oh-my-zsh/custom/themes/)
ZSH_THEME="empty"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(
  # asdf completion
  asdf
  # aws completion
  aws
  colored-man-pages
  # unzip / un-tar in a single command line
  extract
  # interactive git
  forgit
  # map ctrl+g to find file
  fzf-custom
  # completion selection menu with fzf: https://github.com/Aloxaf/fzf-tab
  fzf-tab
  # collection of fzf-tab's source: https://github.com/Freed-Wu/fzf-tab-source
  fzf-tab-source
  git-extra-commands
  git-open
  # faster git status for spaceship prompt
  #gitstatus
  #gitstatus-prompt
  # httpie completion
  httpie
  jira
  # quarkus completion
  #quarkus
  # ripgrep completion
  #ripgrep
  # easily navigate to saved folders
  wd
  # access to most visited directories
  z
  # add quotes automatically to commands: https://github.com/ianthehenry/zsh-autoquoter
  zsh-autoquoter
  # suggestion commands based on command history: https://github.com/zsh-users/zsh-autosuggestions
  zsh-autosuggestions
  # add syntax highlighting: https://github.com/zsh-users/zsh-syntax-highlighting
  zsh-syntax-highlighting
  # better vi mode: https://github.com/jeffreytse/zsh-vi-mode
  zsh-vi-mode
)

source $ZSH/oh-my-zsh.sh

# --------------------------------------------------------
# OPTIONS
# --------------------------------------------------------

# Spell check commands! (Sometimes annoying)
setopt CORRECT

# 10 second wait if you do something that will delete everything.
setopt RM_STAR_WAIT

# Only fools wouldn't do this ;-)
export EDITOR="nvim"

# If I could disable Ctrl-s completely I would!
setopt NO_FLOW_CONTROL

# Beeps are annoying
setopt NO_BEEP

# Extension to do cmd like "rm -rf ^file/folder"
setopt extended_glob

# zsh-navigation-tools config
znt_list_bold=0
znt_list_border=1
znt_list_instant_select=1
znt_history_active_text=reverse

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# --------------------------------------------------------
# Initialization
# --------------------------------------------------------

# ensure other plugins keybinding are preserved when using zsh-vi-mode
# see https://github.com/jeffreytse/zsh-vi-mode#initialization-mode
function zvm_after_init() {
  source "${ZSH}/plugins/fzf/fzf.plugin.zsh"
  source "${ZSH}/custom/plugins/navi/navi.plugin.zsh"
  source "${ZSH}/custom/plugins/pet/pet.plugin.zsh"
  source "${ZSH}/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"
}

# aliases
if [ -f ~/.aliases ]; then
  . ~/.aliases
fi

# Work specific environment variables
if [ -f ~/.work.zsh ]; then
  source ~/.work.zsh
fi

# mass rename
autoload zmv
# calculator
autoload zcalc

# completion for aliases (see https://unix.stackexchange.com/a/583743)
unsetopt completealiases

# Add autocompletion
fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit -i

# Star Ship prompt
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi
