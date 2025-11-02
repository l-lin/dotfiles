---
name: backlog-implement
description: Implement backlog tasks following proper workflow, checking acceptance criteria, and completing Definition of Done
allowed-tools: Bash(backlog:*), Read, Grep, Glob, Write, Edit
---

# Backlog Task Implementation Skill

## Core Mission

Execute task implementation following proper workflow: set status, create plan, implement, check ACs, document, verify DoD.

---

# ⚠️ CRITICAL: NEVER EDIT TASK FILES DIRECTLY. Edit Only via CLI

**ALL task operations MUST use the Backlog.md CLI commands**

- ✅ **DO**: Use `backlog task edit` for all modifications
- ✅ **DO**: Use `backlog task edit <id> --check-ac <index>` to mark acceptance criteria
- ✅ **DO**: Use `backlog task edit <id> -s "In Progress" -a @{myself}` when starting work
- ❌ **DON'T**: Edit markdown files directly
- ❌ **DON'T**: Manually change checkboxes in files
- ❌ **DON'T**: Add or modify text in task files without using CLI

**Why?** Direct file editing breaks metadata synchronization, Git tracking, and task relationships.

---

## 1. Implementing Tasks

### 1.1. First step when implementing a task

The very first things you must do when you take over a task are:

- set the task in progress
- assign it to yourself

```bash
# Example
backlog task edit 42 -s "In Progress" -a @{myself}
```

### 1.2. Create an Implementation Plan (The "how")

Previously created tasks contain the why and the what. Once you are familiar with that part you should think about a
plan on **HOW** to tackle the task and all its acceptance criteria. This is your **Implementation Plan**.

First do a quick check to see if all the tools that you are planning to use are available in the environment you are
working in.

When you are ready, write it down in the task so that you can refer to it later.

```bash
# Example
backlog task edit 42 --plan "1. Research codebase for references\\n2. Research on internet for similar cases\\n3. Implement\\n4. Test"
```

### Multi‑line Input (Description/Plan/Notes)

The CLI preserves input literally. Shells do not convert `\\n` inside normal quotes. Use one of the following to insert real newlines:

- Bash/Zsh (ANSI‑C quoting):
  - Description: `backlog task edit 42 --desc $'Line1\\nLine2\\n\\nFinal'`
  - Plan: `backlog task edit 42 --plan $'1. A\\n2. B'`
  - Notes: `backlog task edit 42 --notes $'Done A\\nDoing B'`
  - Append notes: `backlog task edit 42 --append-notes $'Progress update line 1\\nLine 2'`
- POSIX portable (printf):
  - `backlog task edit 42 --notes "$(printf 'Line1\\nLine2')"`
- PowerShell (backtick n):
  - `backlog task edit 42 --notes "Line1\`nLine2"`

Do not expect `"...\\n..."` to become a newline. That passes the literal backslash + n to the CLI by design.

### 1.3. Implementation

Once you have a plan, you can start implementing the task. This is where you write code, run tests, and make sure
everything works as expected. Follow the acceptance criteria one by one and MARK THEM AS COMPLETE as soon as you
finish them.

```bash
# Check AC as you complete them
backlog task edit 42 --check-ac 1  # Completed first AC
backlog task edit 42 --check-ac 2  # Completed second AC

# Or check multiple at once
backlog task edit 42 --check-ac 1 --check-ac 2 --check-ac 3
```

### 1.4 Implementation Notes (PR description)

When you are done implementing a task you need to prepare a PR description for it.
Because you cannot create PRs directly, write the PR as a clean description in the task notes.
Append notes progressively during implementation using `--append-notes`:

```bash
# Append notes progressively
backlog task edit 42 --append-notes "Implemented X" --append-notes "Added tests"

# Or replace notes entirely
backlog task edit 42 --notes "Implemented using pattern X because Reason Y, modified files Z and W"
```

**Implementation Notes Formatting:**

- Keep implementation notes human-friendly and PR-ready: use short paragraphs or
  bullet lists instead of a single long line.
- Lead with the outcome, then add supporting details (e.g., testing, follow-up
  actions) on separate lines or bullets.
- Prefer Markdown bullets (`-` for unordered, `1.` for ordered) so Maintainers
  can paste notes straight into GitHub without additional formatting.
- When using CLI flags like `--append-notes`, remember to include explicit
  newlines. Example:

  ```bash
  backlog task edit 42 --append-notes $'- Added new API endpoint\\n- Updated tests\\n- TODO: monitor staging deploy'
  ```

**IMPORTANT**: Do NOT include an Implementation Plan when creating a task. The plan is added only after you start the
implementation.

- Creation phase: provide Title, Description, Acceptance Criteria, and optionally labels/priority/assignee.
- When you begin work, switch to edit, set the task in progress and assign to yourself
  `backlog task edit <id> -s "In Progress" -a "..."`.
- Think about how you would solve the task and add the plan: `backlog task edit <id> --plan "..."`.
- Add Implementation Notes only after completing the work: `backlog task edit <id> --notes "..."` (replace) or append progressively using `--append-notes`.

## Phase discipline: What goes where

- Creation: Title, Description, Acceptance Criteria, labels/priority/assignee.
- Implementation: Implementation Plan (after moving to In Progress and assigning to yourself).
- Wrap-up: Implementation Notes (Like a PR description), AC and Definition of Done checks.

**IMPORTANT**: Only implement what's in the Acceptance Criteria. If you need to do more, either:

1. Update the AC first: `backlog task edit 42 --ac "New requirement"`
2. Or create a new follow up task: `backlog task create "Additional feature"`

---

## 2. Typical Workflow

```bash
# 1. Identify work
backlog task list -s "To Do" --plain

# 2. Read task details
backlog task 42 --plain

# 3. Start work: assign yourself & change status
backlog task edit 42 -s "In Progress" -a @myself

# 4. Add implementation plan
backlog task edit 42 --plan "1. Analyze\\n2. Refactor\\n3. Test"

# 5. Work on the task (write code, test, etc.)

# 6. Mark acceptance criteria as complete (supports multiple in one command)
backlog task edit 42 --check-ac 1 --check-ac 2 --check-ac 3  # Check all at once
# Or check them individually if preferred:
# backlog task edit 42 --check-ac 1
# backlog task edit 42 --check-ac 2
# backlog task edit 42 --check-ac 3

# 7. Add implementation notes (PR Description)
backlog task edit 42 --notes "Refactored using strategy pattern, updated tests"

# 8. Mark task as done
backlog task edit 42 -s Done
```

---

## 3. Definition of Done (DoD)

A task is **Done** only when **ALL** of the following are complete:

### ✅ Via CLI Commands:

1. **All acceptance criteria checked**: Use `backlog task edit <id> --check-ac <index>` for each
2. **Implementation notes added**: Use `backlog task edit <id> --notes "..."`
3. **Status set to Done**: Use `backlog task edit <id> -s Done`

### ✅ Via Code/Testing:

4. **Tests pass**: Run test suite and linting
5. **Documentation updated**: Update relevant docs if needed
6. **Code reviewed**: Self-review your changes
7. **No regressions**: Performance, security checks pass

⚠️ **NEVER mark a task as Done without completing ALL items above**

---

## 4. CLI Command Reference for Implementation

### Acceptance Criteria Management

| Action             | Command                                                                     |
| ------------------ | --------------------------------------------------------------------------- |
| Check AC #1        | `backlog task edit 42 --check-ac 1`                                         |
| Check multiple ACs | `backlog task edit 42 --check-ac 1 --check-ac 3`                            |
| Uncheck AC #3      | `backlog task edit 42 --uncheck-ac 3`                                       |
| Mixed operations   | `backlog task edit 42 --check-ac 1 --uncheck-ac 2 --remove-ac 3 --ac "New"` |

### Task Content

| Action           | Command                                                   |
| ---------------- | --------------------------------------------------------- |
| Add plan         | `backlog task edit 42 --plan "1. Step one\\n2. Step two"` |
| Add notes        | `backlog task edit 42 --notes "Implementation details"`   |
| Append notes     | `backlog task edit 42 --append-notes "Additional info"`   |
| Add dependencies | `backlog task edit 42 --dep task-1 --dep task-2`          |

### Task Modification

| Action        | Command                                 |
| ------------- | --------------------------------------- |
| Change status | `backlog task edit 42 -s "In Progress"` |
| Assign        | `backlog task edit 42 -a @sara`         |
| Mark as done  | `backlog task edit 42 -s Done`          |

---

## 5. Quick Reference: DO vs DON'T

### Modifying Tasks

| Task          | ✅ DO                                | ❌ DON'T                          |
| ------------- | ------------------------------------ | --------------------------------- |
| Check AC      | `backlog task edit 42 --check-ac 1`  | Change `- [ ]` to `- [x]` in file |
| Add notes     | `backlog task edit 42 --notes "..."` | Type notes into .md file          |
| Change status | `backlog task edit 42 -s Done`       | Edit status in frontmatter        |
| Add plan      | `backlog task edit 42 --plan "..."`  | Write plan directly in file       |

---

## Common Issues

| Problem              | Solution                                                           |
| -------------------- | ------------------------------------------------------------------ |
| AC won't check       | Use correct index: `backlog task 42 --plain` to see AC numbers     |
| Changes not saving   | Ensure you're using CLI, not editing files                         |
| Metadata out of sync | Re-edit via CLI to fix: `backlog task edit 42 -s <current-status>` |

---

## Remember: The Golden Rule

**🎯 If you want to change ANYTHING in a task, use the `backlog task edit` command.**
**📖 Use CLI to read tasks, exceptionally READ task files directly, never WRITE to them.**

Full help available: `backlog --help`
