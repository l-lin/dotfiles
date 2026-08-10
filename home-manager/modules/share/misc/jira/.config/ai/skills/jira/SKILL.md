---
name: jira
description: Use when a request involves Jira tickets, issue keys like FOO-123, or a Jira queue, especially to inspect, edit, comment on, or transition work with Atlassian CLI `acli`.
---

1. Check access and target first.
   - If the request names a ticket, start with `acli jira workitem view ISSUE-KEY`.
   - If the request is about a queue or search, use `acli jira workitem search` with the narrowest JQL or filter that answers it.
   - If auth or account context looks wrong, run `acli jira auth status`.
2. Check the issue before change.
   - Read the current summary, status, assignee, description, and comments before you edit, comment, or transition it.
   - Use `--fields` on `acli jira workitem view` or `acli jira workitem comment list --key ISSUE-KEY` when you need a tighter read.
   - Do not guess ticket keys, workflow status names, filters, or account identifiers.
3. Change with the narrowest command.
   - Use `acli jira workitem edit` for fields, `acli jira workitem comment create` for updates, `acli jira workitem transition` for status changes, and `acli jira workitem view --web` when a browser view is the fastest proof.
   - Prefer non-interactive flags only when the user already gave the exact text, target status, or field values.
4. Check the result after change.
   - Re-run `acli jira workitem view ISSUE-KEY` after any mutation, and re-read comments when you added or edited one.
   - Report the decisive result: what changed, the new status or field values, or the blocker.
5. Show the outcome, not the manual.
   - Keep the reply task-shaped: issue key, action, result, blocker.
   - Use `references/COMMANDS.md` only when you need exact syntax, field names, or troubleshooting.
