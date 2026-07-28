---
name: jira
description: Use when a request involves Jira tickets, issue keys like FOO-123, or a Jira queue, especially to inspect, edit, comment on, open, or transition work with the `jira` CLI.
---

1. Check access and target first.
   - If the request names a ticket, start with `jira issue view ISSUE-KEY --comments 5`.
   - If the request is about a queue or search, use `jira issue list` with the narrowest filter that answers it.
   - If auth or project context looks wrong, run `jira me` and, if needed, add `-p PROJECT`.
2. Check the issue before change.
   - Read the current summary, status, assignee, and recent comments before you edit, comment, or move it.
   - Do not guess ticket keys, workflow state names, or project defaults.
3. Change with the narrowest command.
   - Use `jira issue edit` for fields, `jira issue comment add` for updates, `jira issue move` for transitions, and `jira open` when a browser view is the fastest proof.
   - Prefer non-interactive flags only when the user already gave the exact text or target state.
4. Check the result after change.
   - Re-run `jira issue view ISSUE-KEY --comments 5` after any mutation.
   - Report the decisive result: what changed, the new status, or the blocker.
5. Show the outcome, not the manual.
   - Keep the reply task-shaped: issue key, action, result, blocker.
   - Use `references/COMMANDS.md` only when you need exact syntax or troubleshooting.
