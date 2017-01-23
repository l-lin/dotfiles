# If not running interactively, do not do anything
[[ $- != *i* ]] && return
[[ -z "$TMUX" ]] && exec tmux

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
# ZSH_THEME="robbyrussell"
ZSH_THEME="crunch"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="yyyy-mm-dd"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git zsh-syntax-highlighting z)

source $ZSH/oh-my-zsh.sh

# --------------------------------------------------------
# ALIASES 
# --------------------------------------------------------
alias sz="source ~/.zshrc"
alias ez="vim ~/.zshrc"
alias agi="sudo apt-get install"
alias agr="sudo apt-get remove"
alias v="vim"
alias g="git"
alias gr="/usr/local/bin/gr"
alias grep="grep --color=auto"
# copy with a progress bar.
alias cpv="rsync -poghb --backup-dir=/tmp/rsync -e /dev/null --progress --"
# Compute space disk
alias df="df -Th"
alias du="du -sh *"
# Record a GIF
alias gif="byzanz-record --duration=20 --x=0 --y=115 --width=1440 --height=745 ~/tmp/byzanz.gif"
# Stellar - DB snaphost https://github.com/fastmonkeys/stellar
alias stellars="stellar snapshot"
alias stellarr="stellar restore"
alias stellarl="stellar list"
# Check used port
alias usedports="netstat -taupen"
alias whousethatport="lsof -i" # losf -i :8000
alias rmf="rm -rf"
diffWithColor() {
    diff -u $1 $2|colordiff|less -R
}
alias diffc="diffWithColor"
# tar
alias tarx="tar xzvf"
alias tarc="tar czvf"
# sudo
alias sudo="sudo "
alias _="sudo "
alias please="sudo "

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
# NODEJS should be installed for root user too, so https://github.com/tj/n can be installed too
export NODEJS_HOME="$APPS_HOME/nodejs"
export GRADLE_HOME="$APPS_HOME/gradle"

export PATH="/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:$HOME/bin"
export PATH="$JAVA_HOME/bin:$MAVEN_HOME/bin:$SCALA_HOME/bin:$PLAY_HOME/bin:$ACTIVATOR_HOME:$SBT_HOME/bin:$GAE_HOME/bin:$HEROKU_HOME/bin:$GOROOT/bin:$GOPATH/bin:$GRADLE_HOME/bin:$PATH"

export GREP_COLOR=32

# --------------------------------------------------------
# OPTIONS
# --------------------------------------------------------

# why would you type 'cd dir' if you could just type 'dir'?
setopt AUTO_CD

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

# --------------------------------------------------------
# cowsay
fortune | cowsay -f $(/bin/ls /usr/share/cowsay/cows -1 | head -n $(expr $$$(date +%s) % $(ls /usr/share/cowsay/cows | wc -w) + 1) | tail -n 1)
# --------------------------------------------------------

