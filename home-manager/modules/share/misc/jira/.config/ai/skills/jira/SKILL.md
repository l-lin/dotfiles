---
name: jira
description: Use when a request involves Jira issue keys or URLs, queues, or creating, editing, commenting on, linking, or transitioning Jira work items.
---

1. **Inspect.** Check access and target first.
   - For one issue, start with `acli jira workitem view ISSUE-KEY`.
   - For a queue or search, use the narrowest `acli jira workitem search` JQL or filter.
   - If auth or account context looks wrong, run `acli jira auth status`.
   - Read the current summary, status, assignee, description, comments, parent, and links before changing anything relevant.
   - Do not guess issue keys, status names, filters, account identifiers, or link types.
2. **Plan.** Make the mutation idempotent and explicit.
   - For bulk work, show the exact issue set, intended fields or links, dependency order, and cleanup or rollback plan before the first mutation. Wait for approval of that exact plan unless the user already approved the same list and operations.
   - Search for existing issues by parent and distinctive summary before creating anything. Do not create a replacement set until every existing target has an explicit mapping or disposition.
   - Stage bulk work: create or edit one representative issue, verify it, then continue. Never run an unreviewed loop for create, edit, link, transition, delete, or archive operations.
   - Treat `--yes` as a safety override, not a convenience. Use it only when the target, operation, and exact values are already explicit.
3. **Mutate.** Use the narrowest command and stop on unexpected results.
   - Use `acli jira workitem edit` for fields, `comment create` for comments, `link create` for links, and `transition` for status changes.
   - After a timeout or error, inspect Jira before retrying. The first request may have succeeded.
   - If a bulk operation partially succeeds, stop. Do not rerun the whole batch or perform cleanup mutations without reporting the completed keys and getting direction.
4. **Verify.** Prove the result from Jira.
   - Re-run `acli jira workitem view` after each mutation and re-read comments after adding or editing one.
   - For bulk work, verify the exact count, keys, parent, fields, links, and statuses after each stage. Check that no duplicate issues were created.
   - Report partial completion and blockers plainly. Use `references/COMMANDS.md` only when exact syntax, fields, or troubleshooting details are needed.

Report the target, action, decisive verification result, and any partial state or blocker. Do not report a bulk operation as complete because the command exited successfully; Jira is the source of truth.
