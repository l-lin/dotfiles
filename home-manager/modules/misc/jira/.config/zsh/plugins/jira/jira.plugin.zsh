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
  eval "${cmd}" \
    | fzf \
      --no-reverse \
      --header-lines 1 \
      --preview-window 'top:70%:border-bottom:hidden' \
      --preview 'jira issue view {1}' \
      --bind '?:toggle-preview' \
      --bind 'alt-p:toggle-preview-wrap' \
      --bind "alt-a:execute(jira issue assign {1} $(jira me))+reload(${cmd})" \
      --bind 'alt-c:execute(jira issue comment add {1})' \
      --bind "alt-e:execute(jira issue edit {1})+reload(${cmd})" \
      --bind "alt-m:execute(jira issue move {1})+reload(${cmd})" \
      --bind 'ctrl-b:execute(jira open {1})' \
      --bind "ctrl-r:reload(${cmd})" \
      --bind "alt-u:execute(jira issue assign {1} x)+reload(${cmd})" \
      --bind 'ctrl-y:execute-silent(echo -n {1} | xsel -b)' \
      --bind "enter:execute(jira issue view {1})" \
      --header 'A-a: assign to me | A-c: add comment | A-e: edit | A-m: move | C-b: open | C-r: reload | A-u: unassign | C-y: yank id | ?: toggle preview'
}

zle -N _jira_issue_interactive
bindkey '^s' _jira_issue_interactive
