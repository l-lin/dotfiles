# If not running interactively, do not do anything
[[ $- != *i* ]] && return
[[ -z "$TMUX" ]] && exec tmux -2 -u

# uncomment the following to benchmark your shell
# start a new session, and call `zprof`
#zmodload zsh/zprof

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
export ZSH_CUSTOM=$ZSH/custom

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="robbyrussell"
#ZSH_THEME="crunch"
ZSH_THEME="tofono"

# fzf options
export FZF_DEFAULT_OPTS="
--ansi
--color fg:#D8DEE9,bg:-1,hl:#A3BE8C,fg+:#D8DEE9,bg+:#434C5E,hl+:#A3BE8C
--color pointer:#BF616A,info:#4C566A,spinner:#4C566A,header:#4C566A,prompt:#81A1C1,marker:#EBCB8B
--bind='?:toggle-preview'
--bind='alt-p:toggle-preview-wrap'
--preview-window='right:60%:wrap'
"
export FZF_TMUX_OPTS="-p 80%,80%"
# preview content of the file under the cursor when searching for a file
export FZF_CTRL_T_OPTS="--preview 'bat --style numbers,changes --color "always" {} 2 >/dev/null | head -200'"
# preview full command
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:5:wrap"
# show the entries of the directory
export FZF_ALT_C_OPTS="--sort --preview 'tree -C {} | head -200'"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(
  asdf
  aws
  colored-man-pages
  copyfile
  copypath
  extract
  forgit
  fzf
  fzf-preview
  git-extra-commands
  git-open
  httpie
  navi
  pet
  quarkus
  ripgrep
  web-search
  wd
  z
  zsh-autoquoter
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# --------------------------------------------------------
# ALIASES
# --------------------------------------------------------

if [ -f ~/.aliases ]; then
  . ~/.aliases
fi

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

# zsh-autosuggestions config
# must choose a value greater than 8, see https://github.com/zsh-users/zsh-autosuggestions/issues/698
# for the complete list of 256 colors: https://upload.wikimedia.org/wikipedia/commons/1/15/Xterm_256color_chart.svg
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=244"
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=10

# zsh-syntax-highlighting config
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern zaq)

# zsh-navigation-tools config
znt_list_bold=0
znt_list_border=1
znt_list_instant_select=1
znt_history_active_text=reverse

# zsh-autoquoter configuration
ZAQ_PREFIXES=(
  'g ci( [^ ]##)# -[^ -]#m'
  'g commit( [^ ]##)# -[^ -]#m'
  'g stash save( [^ ]##)#'
)

# --------------------------------------------------------
# Initialization
# --------------------------------------------------------

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

