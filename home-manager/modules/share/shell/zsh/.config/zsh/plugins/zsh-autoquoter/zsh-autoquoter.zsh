#!/usr/bin/env zsh
#
# zsh-autoquoter configuration
#

export ZAQ_PREFIXES=(
  'git ci( [^ ]##)# -[^ -]#m'
  'git commit( [^ ]##)# -[^ -]#m'
  'git stash save( [^ ]##)#'
  'ddgr( [^ ]##)#'
  'gh copilot explain( [^ ]##)#'
  'gh copilot suggest( [^ ]##)#'
  'claude -p( [^ ]##)#'
)

if [[ -v ZSH_HIGHLIGHT_HIGHLIGHTERS ]]; then
  ZSH_HIGHLIGHT_HIGHLIGHTERS+=("zaq")
fi
