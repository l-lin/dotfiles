---
description: Debug and investigate
---

# Debug

You are tasked with helping debug issues during manual testing or implementation. This command allows you to investigate problems by examining logs, database state, and git history without editing files. Think of this as a way to bootstrap a debugging session without using the primary window's context.

## Initial Response

When invoked WITH a plan/ticket file:

```
I'll help debug issues with [file name]. Let me understand the current state.

What specific problem are you encountering?
- What were you trying to test/implement?
- What went wrong?
- Any error messages?

I'll investigate the codebase and git state to help figure out what's happening.
```

When invoked WITHOUT parameters:

```
I'll help debug your current issue.

Please describe what's going wrong:
- What are you working on?
- What specific problem occurred?
- When did it last work?

I can investigate codebase, and recent changes to help identify the issue.
```

## Process Steps

### Step 1: Understand the Problem

After the user describes the issue:

1. **Read any provided context** (plan or ticket file):
   - Understand what they're implementing/testing
   - Note which phase or step they're on
   - Identify expected vs actual behavior

2. **Quick state check**:
   - Current git branch and recent commits
   - Any uncommitted changes
   - When the issue started occurring

### Step 2: Investigate the Issue

Spawn parallel Task agents for efficient investigation.

```
Task 1 - Codebase:
Investigate the codebase for clues about the issue:
1. Read relevant files mentioned in the problem description
2. Check for error patterns in logs or console output
3. Look for related configuration files
4. Examine test files for expected behavior
5. Search for similar code patterns that work
6. Check for missing imports, typos, or syntax issues
Return: Code analysis and potential issues found
```

```
Task 2 - Git and File State:
Understand what changed recently:
1. Check git status and current branch
2. Look at recent commits: git log --oneline -10
3. Check uncommitted changes: git diff
4. Verify expected files exist
5. Look for any file permission issues
Return: Git state and any file issues
```

### Step 3: Present Findings

Based on the investigation, present a focused debug report:

````markdown
## Debug Report

### What's Wrong

[Clear statement of the issue based on evidence]

### Evidence Found

**From Codebase** (`path/to/some/file.rb`):

- [Error/warning with timestamp]
- [Pattern or repeated issue]

**From Git/Files**:

- [Recent changes that might be related]
- [File state issues]


### Root Cause

[Most likely explanation based on evidence]

### Next Steps

1. **Try This First**:

   ```bash
   [Specific command or action]
   ```

2. **If That Doesn't Work**:
   - [Alternative step 1]
   - [Alternative step 2]

### Can't Access?

Some issues might be outside my reach:

- Browser console errors (F12 in browser)
- MCP server internal state
- System-level issues

Would you like me to investigate something specific further?

````

## Important Notes

- **Focus on manual testing scenarios** - This is for debugging during implementation
- **Always require problem description** - Can't debug without knowing what's wrong
- **Read files completely** - No limit/offset when reading context
- **Guide back to user** - Some issues (browser console, MCP internals) are outside reach
- **No file editing** - Pure investigation only

## Quick Reference

**Codebase analyzer**: Use the sub-agent @codebase-analyzer for efficient analysis.

**Git State**: Use the sub-agent @git-investigator for efficient investigation.

Remember: This command helps you investigate without burning the primary window's context. Perfect for when you hit an issue during manual testing and need to dig into logs, database, or git state.
