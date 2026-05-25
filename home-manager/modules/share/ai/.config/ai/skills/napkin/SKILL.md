---
name: napkin
description: Use when maintaining a per-repo runbook of recurring, repo-specific guidance that is not already covered by the system prompt, AGENTS files, or the active task docs
---

# Napkin

Napkin is a tiny per-repo runbook, not a session log or a second `AGENTS.md`.

Keep it sparse. Do not copy generic rules already covered by the system prompt, `AGENTS.md`, or the active task docs. Keep only recurring, repo-specific guidance that repeatedly saves time or avoids mistakes. The `napkin` skill manages the full format and curation policy.

**This skill is always active. Every session. No trigger required.**

## Session Start: Read And Curate

First thing each session, read `.sandbox/napkin.md` and apply it silently.

Curate it immediately after reading:
- Re-prioritize items by importance.
- Merge duplicates and delete stale or low-signal notes.
- Delete notes that merely repeat the system prompt, `AGENTS.md`, README rules, or one-off task instructions.
- Keep the file sparse. If two notes matter, keep two notes.
- Ensure each item contains a concrete `Do instead:` action.
- Enforce top 5 items per category.

If no napkin exists yet, create one at `.sandbox/napkin.md`:

```markdown
# Napkin Runbook

## Execution & Validation (Highest Priority)
1. **[YYYY-MM-DD] Short rule**
   Do instead: concrete repeatable action.

## Shell & Command Reliability
1. **[YYYY-MM-DD] Short rule**
   Do instead: concrete repeatable action.

## Domain Behavior Guardrails
1. **[YYYY-MM-DD] Short rule**
   Do instead: concrete repeatable action.

## User Directives
1. **[YYYY-MM-DD] Directive**
   Do instead: exactly follow this preference.
```

Adapt categories to the repo and keep the priority ordering. Empty categories are fine.

## Continuous Runbook Updates

Update during work whenever you learn something reusable.

Add a note only if it will matter again.

Good candidates:
- Repo-specific gotchas or toolchain traps.
- User preferences that recur across tasks.
- Non-obvious tactics that repeatedly work.

Do not include:
- Timeline notes or current task status.
- Verbose postmortems.
- Generic rules already covered elsewhere.
- Mistake logs without a concrete `Do instead:` fix.

## Entry Format Requirements

Each entry must:
- Include date added, `[YYYY-MM-DD]`.
- Use a short, specific title.
- Include an explicit `Do instead:` line.
- Stay concise and make sense when read alone.

## Category And Priority Policy

- Organize notes by category.
- Sort each category by importance.
- Maximum 5 items per category.
- Prefer fewer high-signal items over broad coverage.
- If a category fills up, delete the weakest item.

## Practical Rule

Treat napkin as a live runbook for recurring leverage. If it starts reading like a log or a second copy of `AGENTS.md`, trim it.

## Example Entry

```markdown
1. **[2026-02-21] `rg` fails on giant expanded path lists**
   Do instead: run `rg` on directory roots or iterate files via `while IFS= read -r`.
```
