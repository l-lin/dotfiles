# Atlassian CLI Jira command patterns

Verified against local `acli --help`, `acli jira --help`, and `acli jira workitem {view,search,edit,comment create,comment list,transition} --help` on 2026-08-10.

## Inspect one issue

```bash
acli jira workitem view ISSUE-123
acli jira workitem view ISSUE-123 --fields key,summary,status,assignee,description
acli jira workitem view ISSUE-123 --fields summary,comment --json
acli jira workitem view ISSUE-123 --web
acli jira workitem comment list --key ISSUE-123 --limit 5
```

## Find issues

```bash
acli jira workitem search --jql 'assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC'
acli jira workitem search --jql 'project = TEAM AND text ~ "feature request"' --fields key,summary,status,assignee
acli jira workitem search --filter 10001 --limit 25 --json
acli jira workitem search --jql 'project = TEAM' --count
```

## Edit fields

```bash
acli jira workitem edit --key ISSUE-123 --summary "New summary"
acli jira workitem edit --key ISSUE-123 --description "New description" --yes
acli jira workitem edit --key ISSUE-123 --description-file /path/to/description.md --yes
acli jira workitem edit --key ISSUE-123 --assignee @me --labels bug,urgent --yes
```

## Add comments

```bash
acli jira workitem comment create --key ISSUE-123 --body "Single-line comment"
acli jira workitem comment create --key ISSUE-123 --body $'Line 1\n\nLine 2'
acli jira workitem comment create --key ISSUE-123 --body-file /path/to/comment.md
acli jira workitem comment create --key ISSUE-123 --editor
```

## Transition an issue

```bash
acli jira workitem transition --key ISSUE-123 --status "In Progress"
acli jira workitem transition --key ISSUE-123 --status "Done" --yes
```

Status names are workflow-specific. Use the exact status Jira exposes for that work item.

## Troubleshoot

```bash
acli jira auth status
acli jira auth login --web
acli jira workitem view ISSUE-123 --json
```
