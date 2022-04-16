# If not running interactively, do not do anything
[[ $- != *i* ]] && return
[[ -z "$TMUX" ]] && exec tmux

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
export ZSH_CUSTOM=$ZSH/custom

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="robbyrussell"
#ZSH_THEME="crunch"
ZSH_THEME="spaceship"

# Configure spaceship prompt
export SPACESHIP_TIME_SHOW=true
export SPACESHIP_DIR_LOCK_SYMBOL=" "
export SPACESHIP_PROMPT_ORDER=(
  time
  user
  dir
  host
  git
  hg
  package
  node
  exec_time
  line_sep
  battery
  vi_mode
  jobs
  exit_code
  char
)

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="yyyy-mm-dd"

# fzf options
export FZF_BASE="$HOME/.asdf/installs/fzf/0.25.1"
export FZF_DEFAULT_OPTS="
--ansi
--height='80%'
--bind='alt-k:preview-up,alt-p:preview-up'
--bind='alt-j:preview-down,alt-n:preview-down'
--bind='?:toggle-preview'
--bind='alt-w:toggle-preview-wrap'
--preview-window='right:60%'
"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(
  z
  git-open
  copyfile
  copypath
  colored-man-pages
  extract
  web-search
  zsh-autosuggestions
  zsh-syntax-highlighting
  httpie
  wd
  forgit
  pet
  fzf
  fzf-preview
  dip
  asdf
  git-extra-commands
)

source $ZSH/oh-my-zsh.sh

# --------------------------------------------------------
# ALIASES 
# --------------------------------------------------------

if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

# --------------------------------------------------------
# User configuration
# --------------------------------------------------------

export APPS_HOME="$HOME/apps"

export PATH="$HOME/bin:$PATH"

export ANSIBLE_CALLBACK_PLUGINS="$HOME/apps/ansible_stdout_compact_logger"
export ANSIBLE_STDOUT_CALLBACK="anstomlog"

export GREP_COLOR=32

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
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=1"
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=10

# zsh-syntax-highlighting config
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

# zsh-navigation-tools config
znt_list_bold=0
znt_list_border=1
znt_list_instant_select=1
znt_history_active_text=reverse

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

# Add autocompletion
fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit -i

