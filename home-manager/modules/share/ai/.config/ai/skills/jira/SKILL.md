---
name: jira
description: Manage JIRA tickets. Use it when the user mentions JIRA with ticket IDs like FOO-123.
---

# Jira CLI Skill

You are a Jira CLI expert assistant using [jira-cli](https://github.com/ankitpokhrel/jira-cli).

## Issue Management Commands

### View Issue

```bash
jira issue view ISSUE-KEY [--comments N]
```

- View complete issue details
- Use `--comments 5` to see recent comments
- Use `--raw` to get raw JSON response

### Edit Issue

```bash
jira issue edit ISSUE-KEY -s"New Title" -b"New Description" [--no-input]
```

- `-s, --summary` - Change issue title
- `-b, --body` - Change issue description
- `--no-input` - Skip interactive prompts
- Can pipe description from stdin: `echo "Description" | jira issue edit ISSUE-KEY --no-input`

### Add Comment

```bash
jira issue comment add ISSUE-KEY "Comment text"
```

- Add single-line comment: `jira issue comment add ISSUE-KEY "My comment"`
- Multi-line comment: `jira issue comment add ISSUE-KEY $'Line 1\n\nLine 2'`
- From file: `jira issue comment add ISSUE-KEY --template /path/to/file`
- From stdin: `echo "Comment" | jira issue comment add ISSUE-KEY`

### Move Issue State

```bash
jira issue move ISSUE-KEY "State Name"
```

Available states:

- `"To Do"`
- `"In progress"`
- `"To be reviewed"`
- `"To be validated"`
- `"Done"`

Examples:

```bash
jira issue move ISSUE-1 "In progress"
jira issue move ISSUE-1 Done --comment "Completed"
```

## Usage Guidelines

1. **Always verify issue key** before operations
2. **Use `jira issue view`** to check current state before editing
3. **Quote state names** that contain spaces (e.g., `"In progress"`)
4. **Verify changes** by viewing the issue after updates

## Error Handling

- Confirm issue exists: `jira issue view <key>`
- Check authentication: `jira me`
- Use `--debug` flag for troubleshooting
