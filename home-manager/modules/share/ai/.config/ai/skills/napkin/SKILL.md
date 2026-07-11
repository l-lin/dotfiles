---
name: napkin
description: "Use at session start and whenever updating `.sandbox/napkin.md`. Owns the durable runbook: what belongs there, what stays out, and how hard to prune it."
---

Napkin is the durable runbook for this repo and this user. It is not session memory and not generalized reusable learning.

## Session start

1. Read `.sandbox/napkin.md` if it exists and apply it silently.
2. If it does not exist, do nothing unless the session uncovers something worth keeping.
3. Do not treat curation as ritual. Clean it up only when you add to it or when noise is getting in the way.

## What belongs

Add a note only if it is likely to matter again:
- repo-specific gotcha or toolchain trap
- recurring user preference
- non-obvious tactic that repeatedly saves time
- stable workflow guidance not already covered by the prompt, `AGENTS.md`, or task docs

## What stays out

Do not put these in `napkin`:
- session timelines, handoffs, or current task status
- long transcripts or postmortems
- generic rules already covered elsewhere
- one-off facts with no likely reuse
- notes without a concrete action

## Note shape

Keep notes short, standalone, and actionable.

```markdown
1. **[YYYY-MM-DD] Short rule**
   Do instead: concrete repeatable action.
```

Use categories only if they help. Do not invent structure for its own sake.

If you create a new file, start with:

```markdown
# Napkin Runbook

## Repo Guardrails
1. **[YYYY-MM-DD] Short rule**
   Do instead: concrete repeatable action.

## User Directives
1. **[YYYY-MM-DD] Preference**
   Do instead: exact behavior.
```

## Curation

If you touch `napkin`, prune aggressively:
- merge duplicates
- delete stale, weak, or obvious notes
- delete notes that duplicate the prompt, `AGENTS.md`, or task docs
- prefer a few high-signal notes over broad coverage
- move task-specific material to the `journal`
- move broadly reusable lessons to the reusable-learning flow

## Example

```markdown
1. **[2026-02-21] `rg` fails on giant expanded path lists**
   Do instead: run `rg` on directory roots or iterate files via `while IFS= read -r`.
```
