#!/usr/bin/env zsh
#
# Feature-rich interactive Jira command line.
# src: https://github.com/ankitpokhrel/jira-cli
#

if ! type jira >/dev/null 2>&1; then
  return
fi

function _jira_issue_interactive() {
  jira issue list -a$(jira me) -s~Done --plain --columns id,status,summary \
    | fzf \
      --header-lines 1 \
      --preview-window 'top:70%:border-bottom:hidden' \
      --preview 'jira issue view {1}' \
      --bind '?:toggle-preview' \
      --bind 'alt-p:toggle-preview-wrap' \
      --bind 'alt-j:preview-down' \
      --bind 'alt-k:preview-up' \
      --bind "alt-a:execute(jira issue assign {1} $(jira me))" \
      --bind 'alt-e:execute(jira issue edit {1})' \
      --bind 'alt-m:execute(jira issue move {1})' \
      --bind 'alt-c:execute(jira issue comment add {1})' \
      --bind 'alt-o:execute(jira open {1})' \
      --bind "alt-y:execute-silent(echo -n {1} | wl-copy)" \
      --header 'A-a: assign to me | A-e: edit | A-m: move | A-c: add comment | A-o: open | A-y: yank id | ?: toggle preview | A-p: toggle preview wrap | A-/: toggle wrap' \
    | awk '{ print $1 }' \
    | wl-copy
}

zle -N _jira_issue_interactive
bindkey '^s' _jira_issue_interactive
