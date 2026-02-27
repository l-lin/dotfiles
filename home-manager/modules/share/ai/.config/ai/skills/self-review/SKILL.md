---
name: self-review
description: Use when code was just written or modified and needs a final quality check before delivery, or when user suspects bugs were introduced during implementation.
---

# Self-Review Protocol

## Overview

Perform a multi-pass self-inspection of all code written or modified in the session. Each pass uses a distinct focus to catch what the previous missed.

## Review Passes

**Default: 3 independent passes.** If user says "review N times", use that number.

For each pass, spawn a **code-reviewer subagent** to review ALL code written or modified in the session against the full checklist. After the subagent reports, the main agent applies fixes before spawning the next subagent. Passes are sequential:

`subagent reviews → main agent fixes → subagent reviews → main agent fixes → ...`

**Full checklist (every pass):**
- **Correctness:** bugs, logic errors, off-by-one, null checks, wrong operators
- **Edge Cases & Errors:** empty/null inputs, boundary values, missing try/catch, unhandled rejections, silent failures
- **Quality & Consistency:** dead code, duplication, resource leaks, naming, style, missing docs

Complete all passes even if early ones find nothing.

## Response Format

**Each pass:**
- Issues found → fix immediately, report `Pass [X/N]: Fixed [M] issue(s).` + brief list
- No issues → report `Pass [X/N]: No issues found.` + brief verification summary

**After all passes:**
`Completed [N] passes. Total fixes: [M]. Review complete.`

## Rules

- Be skeptical — assume issues exist until proven otherwise
- Be honest — report bugs even if embarrassing
- No shortcuts — complete all N passes

## Example

```
Pass 1/3: Fixed 2 issue(s).
1. Added null check in `parseInput()` - crashed on empty string
2. Fixed off-by-one in loop boundary - skipped last element

Pass 2/3: Fixed 1 issue(s).
1. Removed unused parameter `options` in `validate()`

Pass 3/3: No issues found.
Verified: null/undefined handling, error paths, no dead code, resource cleanup, type safety.

Completed 3 passes. Total fixes: 3. Review complete.
```
