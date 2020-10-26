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

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# plugins that took time to load: # nvm kubectl
plugins=(
  z
  git-open
  copyfile
  copydir
  colored-man-pages
  extract
  web-search
  zsh-autosuggestions
  zsh-syntax-highlighting
  httpie
  wd
  forgit
  #kubectl
  nvm
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
export GOPATH="$HOME/go"
export PYENV_ROOT="$APPS_HOME/pyenv"
export WOWZA_PATH="/usr/local/WowzaStreamingEngine"

export PATH="$HOME/bin:$GOPATH/bin:$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"

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

# fzf options
export FZF_DEFAULT_OPTS="
--ansi
--height='80%'
--bind='alt-k:preview-up,alt-p:preview-up'
--bind='alt-j:preview-down,alt-n:preview-down'
--bind='?:toggle-preview'
--bind='alt-w:toggle-preview-wrap'
--preview-window='right:60%'
"

# --------------------------------------------------------
# Initialization
# --------------------------------------------------------

# fuzzyfinder
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
if type fzf >/dev/null 2>&1; then
    function preview() {
        local file
        file=$(ls -t | fzf --preview 'bat --style numbers,changes --color "always" {} | head -500')
        if [[ -f $file ]]; then
            v $file
        elif [[ -d $file ]]; then
            cd $file
            preview
            zle reset-prompt
        fi
    }
    zle -N preview
    bindkey '^q' preview
fi


# pet: https://github.com/knqyf263/pet
if type pet >/dev/null 2>&1; then
    function pet-select() {
        BUFFER=$(pet search --query "$LBUFFER")
        CURSOR=$#BUFFER
        zle redisplay
    }
    zle -N pet-select
    stty -ixon
    bindkey '^s' pet-select

    function pet-register-prev() {
      PREV=$(fc -lrn | head -n 1)
      sh -c "pet new `printf %q "$PREV"`"
    }
fi

# Work specific environment variables
if [ -f ~/.work.zsh ]; then
    source ~/.work.zsh
fi

# Add autocompletion
fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit -i

# Activate pyenv virtualenv
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Activate goland version manager
source "${HOME}/.gvm/scripts/gvm"

# THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="${HOME}/.sdkman"
[[ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ]] && source "${HOME}/.sdkman/bin/sdkman-init.sh"

