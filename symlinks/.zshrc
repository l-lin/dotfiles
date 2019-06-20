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
# plugins that took time to load: nvm kubectl
plugins=(z git-open zsh-navigation-tools copyfile copydir colored-man-pages extract web-search zsh-autosuggestions zsh-syntax-highlighting httpie wd
#    kubectl
#    nvm
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
export JAVA_HOME="$APPS_HOME/java"
export MAVEN_HOME="$APPS_HOME/maven"
export M2_HOME="$MAVEN_HOME"
export SCALA_HOME="$APPS_HOME/scala"
export PLAY_HOME="$APPS_HOME/play"
export ACTIVATOR_HOME="$APPS_HOME/activator"
export TOMCAT_HOME="$APPS_HOME/tomcat"
export SBT_HOME="$APPS_HOME/sbt"
export GAE_HOME="$APPS_HOME/bin"
export HEROKU_HOME="/usr/local/heroku"
export GOROOT="$APPS_HOME/go"
export GOPATH="$HOME/go"
export NODEJS_HOME="$APPS_HOME/nodejs"
export GRADLE_HOME="$APPS_HOME/gradle"
export NVM_DIR="$HOME/.nvm"

export PATH="/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:$HOME/bin:$PATH"
export PATH="$JAVA_HOME/bin:$MAVEN_HOME/bin:$SCALA_HOME/bin:$PLAY_HOME/bin:$ACTIVATOR_HOME:$SBT_HOME/bin:$GAE_HOME/bin:$HEROKU_HOME/bin:$GOROOT/bin:$GOPATH/bin:$GRADLE_HOME/bin:$PATH"

export GREP_COLOR=32

# --------------------------------------------------------
# OPTIONS
# --------------------------------------------------------

# Spell check commands! (Sometimes annoying)
setopt CORRECT

# 10 second wait if you do something that will delete everything.  I wish I'd had this before...
setopt RM_STAR_WAIT

# only fools wouldn't do this ;-)
export EDITOR="vim"

# If I could disable Ctrl-s completely I would!
setopt NO_FLOW_CONTROL

# beeps are annoying
setopt NO_BEEP

# extention to do cmd like "rm -rf ^file/folder"
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

# fuzzyfinder
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

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
fi

# Work specific environment variables
if [ -f ~/.work.zsh ]; then
    source ~/.work.zsh
fi

# Add autocompletion
fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit -i

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="${HOME}/.sdkman"
[[ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ]] && source "${HOME}/.sdkman/bin/sdkman-init.sh"

