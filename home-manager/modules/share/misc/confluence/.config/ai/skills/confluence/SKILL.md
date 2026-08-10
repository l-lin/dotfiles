---
name: confluence
description: Use when a request involves Confluence pages, especially to inspect a page with Atlassian CLI `acli` or to check whether page create or edit is supported.
---

1. Check access and target first.
   - If the request names a page, start with `acli confluence page view --id PAGE-ID`.
   - If auth or account context looks wrong, run `acli confluence auth status`.
2. Check the page before change.
   - Read the current page before you discuss editing or creating related content.
   - Use the narrowest flags that answer the question, such as `--body-format`, `--include-*`, or `--json`.
   - Do not guess page IDs, status values, or body formats.
3. Be explicit about command support.
   - Use `acli confluence page view` for inspection.
   - If the user asks to create or edit a page, check the available `acli confluence page` subcommands first.
   - If `acli` still does not expose page create or edit, say so plainly instead of inventing a command.
4. Check the result after change.
   - Re-run `acli confluence page view --id PAGE-ID` after any supported mutation.
   - Report the decisive result: what you confirmed, what changed, or the blocker.
5. Show the outcome, not the manual.
   - Keep the reply task-shaped: page, action, result, blocker.
   - Use `references/COMMANDS.md` only when you need exact syntax, supported flags, or troubleshooting.
