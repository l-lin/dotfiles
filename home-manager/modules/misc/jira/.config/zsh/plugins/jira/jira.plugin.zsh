#!/usr/bin/env zsh
#
# Feature-rich interactive Jira command line.
# src: https://github.com/ankitpokhrel/jira-cli
#

if ! type jira >/dev/null 2>&1; then
  return
fi

function _jira_issue_interactive() {
  local cmd
  cmd='jira sprint list --current -s~Done --order-by status --plain --columns id,assignee,status,summary'
  jira issue view $(eval "${cmd}" \
    | fzf \
      --header-lines 1 \
      --preview-window 'top:70%:border-bottom:hidden' \
      --preview 'jira issue view {1}' \
      --bind '?:toggle-preview' \
      --bind 'alt-p:toggle-preview-wrap' \
      --bind 'alt-j:preview-down' \
      --bind 'alt-k:preview-up' \
      --bind "alt-a:execute(jira issue assign {1} $(jira me))" \
      --bind 'alt-c:execute(jira issue comment add {1})' \
      --bind 'alt-e:execute(jira issue edit {1})' \
      --bind "alt-m:execute(jira issue move {1})+reload(${cmd})" \
      --bind 'alt-o:execute(jira open {1})' \
      --bind "alt-r:reload(${cmd})" \
      --bind "alt-u:execute(jira issue assign {1} x)" \
      --bind 'alt-y:execute-silent(echo -n {1} | wl-copy)' \
      --header 'A-a: assign to me | A-c: add comment | A-e: edit | A-m: move | A-o: open | A-r: reload | A-u: unassign | A-y: yank id | ?: toggle preview' \
    | awk '{ print $1 }' \
  )
}

zle -N _jira_issue_interactive
bindkey '^s' _jira_issue_interactive
