# Jira CLI command patterns

Verified against local `jira --help` and `jira issue {list,view,edit,comment add,move} --help` on 2026-07-28.

## Inspect one issue

```bash
jira issue view ISSUE-123 --comments 5
jira issue view ISSUE-123 --raw
jira open ISSUE-123
```

## Find issues

```bash
jira issue list --plain --columns key,summary,status,assignee
jira issue list "feature request" --plain
jira issue list -q 'assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC' --plain
```

## Edit fields

```bash
jira issue edit ISSUE-123 -s"New summary" --no-input
jira issue edit ISSUE-123 -b"New description" --no-input
echo "Description from stdin" | jira issue edit ISSUE-123 -s"New summary" --no-input
```

## Add comments

```bash
jira issue comment add ISSUE-123 "Single-line comment"
jira issue comment add ISSUE-123 $'Line 1\n\nLine 2'
jira issue comment add ISSUE-123 --template /path/to/comment.md
echo "Comment from stdin" | jira issue comment add ISSUE-123
```

## Move an issue

```bash
jira issue move ISSUE-123 "Target State"
jira issue move ISSUE-123 "Target State" --comment "Reason"
jira issue move ISSUE-123 "Target State" --comment "Reason" -a "Jane Doe"
```

Transition names are workflow-specific. Use the exact name Jira exposes for that issue.

## Troubleshoot

```bash
jira me
jira serverinfo
jira issue view ISSUE-123 --debug
jira issue view ISSUE-123 -p PROJECT
```
