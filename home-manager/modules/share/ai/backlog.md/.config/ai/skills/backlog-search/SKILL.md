---
name: backlog-search
description: Search, list, filter, and view backlog tasks using fuzzy search and filters
allowed-tools: Bash(backlog:*), Read, Grep, Glob
---

# Backlog Search & Viewing Skill

## Core Mission

Find, list, filter, and view backlog tasks efficiently using CLI commands with `--plain` flag for AI-friendly output.

---

# ⚠️ CRITICAL: Use CLI for All Task Viewing

**Always use Backlog.md CLI commands to view tasks**

- ✅ **DO**: Use `backlog task list --plain` to list tasks
- ✅ **DO**: Use `backlog task 42 --plain` to view specific tasks
- ✅ **DO**: Use `backlog search "keyword" --plain` to search tasks
- ❌ **DON'T**: Browse backlog/tasks folder directly
- ❌ **DON'T**: Use grep/find on task files (use `backlog search` instead)
- ❌ **DON'T**: Read task files directly unless necessary (prefer CLI)

**Why?** CLI provides formatted, AI-friendly output with `--plain` flag and respects task metadata.

---

## 1. Finding Tasks and Content with Search

When users ask you to find tasks related to a topic, use the `backlog search` command with `--plain` flag:

```bash
# Search for tasks about authentication
backlog search "auth" --plain

# Search only in tasks (not docs/decisions)
backlog search "login" --type task --plain

# Search with filters
backlog search "api" --status "In Progress" --plain
backlog search "bug" --priority high --plain
```

**Key points:**

- Uses fuzzy matching - finds "authentication" when searching "auth"
- Searches task titles, descriptions, and content
- Also searches documents and decisions unless filtered with `--type task`
- Always use `--plain` flag for AI-readable output

---

## 2. Listing Tasks

```bash
# List all tasks
backlog task list --plain

# Filter by status
backlog task list -s "To Do" --plain
backlog task list -s "In Progress" --plain
backlog task list -s "Done" --plain

# Filter by assignee
backlog task list -a @sara --plain
backlog task list -a @myself --plain

# Combine filters
backlog task list -s "To Do" -a @myself --plain
```

---

## 3. Viewing Specific Tasks

```bash
# View task details
backlog task 42 --plain

# View multiple tasks (run separately)
backlog task 1 --plain
backlog task 2 --plain
backlog task 3 --plain
```

**Always use `--plain` flag** for clean, AI-friendly output without formatting.

---

## 4. CLI Command Reference for Viewing/Searching

### Task Operations

| Action             | Command                                         |
| ------------------ | ----------------------------------------------- |
| View task          | `backlog task 42 --plain`                       |
| List tasks         | `backlog task list --plain`                     |
| Search tasks       | `backlog search "topic" --plain`                |
| Search with filter | `backlog search "api" --status "To Do" --plain` |
| Filter by status   | `backlog task list -s "In Progress" --plain`    |
| Filter by assignee | `backlog task list -a @sara --plain`            |
| Archive task       | `backlog task archive 42`                       |
| Demote to draft    | `backlog task demote 42`                        |

### Search Options

| Option              | Description                                 | Example                                         |
| ------------------- | ------------------------------------------- | ----------------------------------------------- |
| `--type task`       | Search only tasks (not docs/decisions)      | `backlog search "auth" --type task --plain`     |
| `--status "Status"` | Filter by task status                       | `backlog search "api" --status "To Do" --plain` |
| `--priority level`  | Filter by priority (low/medium/high)        | `backlog search "bug" --priority high --plain`  |
| `--plain`           | Output plain text (AI-friendly, ALWAYS USE) | `backlog search "query" --plain`                |

---

## 5. Quick Reference: DO vs DON'T

### Viewing and Finding Tasks

| Task          | ✅ DO                           | ❌ DON'T                        |
| ------------- | ------------------------------- | ------------------------------- |
| View task     | `backlog task 42 --plain`       | Open and read .md file directly |
| List tasks    | `backlog task list --plain`     | Browse backlog/tasks folder     |
| Check status  | `backlog task 42 --plain`       | Look at file content            |
| Find by topic | `backlog search "auth" --plain` | Manually grep through files     |

---

## 6. Search Workflow Examples

### Finding Tasks About a Feature

```bash
# User asks: "What tasks are related to authentication?"
backlog search "auth" --type task --plain

# More specific: find auth tasks that are pending
backlog search "auth" --status "To Do" --plain
```

### Finding Your Assigned Tasks

```bash
# What am I working on?
backlog task list -s "In Progress" -a @myself --plain

# What's assigned to me to do next?
backlog task list -s "To Do" -a @myself --plain
```

### Finding High Priority Items

```bash
# Find high priority bugs
backlog search "bug" --priority high --plain

# List all high priority tasks
backlog task list --priority high --plain
```

---

## Common Issues

| Problem                | Solution                                             |
| ---------------------- | ---------------------------------------------------- |
| Task not found         | Check task ID with `backlog task list --plain`       |
| Search returns nothing | Try broader keywords, check spelling                 |
| Too many results       | Add filters: `--status`, `--priority`, `--type task` |

---

## Remember: The Golden Rule

**🎯 Always use `backlog search` or `backlog task list` with `--plain` flag to find tasks.**
**📖 Use CLI for viewing - it provides clean, structured, AI-friendly output.**

Full help available: `backlog --help`
