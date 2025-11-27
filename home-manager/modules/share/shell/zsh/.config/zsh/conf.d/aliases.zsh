#!/usr/bin/env zsh
#
# aliases
#

# --------------------------------------------------------
# Shortcuts
# --------------------------------------------------------
# docker
alias d="docker"
alias dc="docker compose"
alias ldo="lazydocker"
# make
alias j="just"
alias m="make"
# ops
alias ap="ansible-playbook"
alias h="helm"
alias k="kubectl"
alias kb="kubetailrb"
alias tf="terraform"
# nix
alias n="nix"
alias ns="nix-shell --command zsh -p"
# editor
alias v="nvim"
# sudo
alias sudo="sudo"
alias _="sudo"
alias please="sudo"
# ruby
alias ru="ruby"
alias be="bundle exec"
alias ra="bundle exec rails"
# git
alias g="git"
alias gw="git worktree"
alias lg="lazygit"
# ai
alias ai='CC_LAYOUT_OVERRIDE=buffer nvim +"CodeCompanionChat Toggle"'
# mise
alias mr="mise run"
alias mw="mise watch"
# vcs
alias review="nvim +'lua Snacks.picker.gh_pr()'"

# --------------------------------------------------------
# Default options
# --------------------------------------------------------
alias top="procs --watch --sortd cpu"
alias watch="viddy"
# Prevent recursive change on root directory
#alias chmod="chmod --preserve-root"
#alias chown="chown --preserve-root"
# copy with a progress bar.
alias cpv="rsync -apoghb --backup-dir=/tmp -e /dev/null --inplace --info=progress2 --"
# Compute space disk
alias df="duf"
alias du="${HOME}/.nix-profile/bin/dust"
# Check used port
alias usedports="netstat -taupen"
alias who-use-that-port="lsof -i" # losf -i :8000
alias rmf="rm -rf"
# tar
alias tarx="tar xzvf"
alias tarc="tar czvf"
# eza
alias l="eza -l --icons -a --group-directories-first"
alias lt="eza --tree --level=2 --long --icons --group-directories-first"
# prettyping
alias ping="prettyping --nolegend"
# ssh support with alacritty
# see https://github.com/alacritty/alacritty/issues/3932 for more info
#alias ssh="TERM=xterm-256color ssh"
# find configured local DNS servers
alias find-dns-servers="nmcli dev show | grep 'IP4.DNS'"
# weather
alias weather="curl https://wttr.in/"
# pandoc
alias pandoc="docker run --rm --volume \${PWD}:/data --user $(id -u):$(id -g) pandoc/core:3.0.1-alpine"
alias pandoc-latex="docker run --rm --volume \${PWD}:/data --user $(id -u):$(id -g) pandoc/latex:3.0.1-alpine"
# awslocal
alias awslocal='aws --endpoint-url=http://localhost:4566'
# termgraph
alias termgraph="docker run --rm --volume \${PWD}:/data --user $(id -u):$(id -g) ghcr.io/l-lin/termgraph:main"
# xh
alias http="xh"
alias https="xhs"
