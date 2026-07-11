---
name: journal
description: "Use at session start, after context compaction, and before session end. Owns session journals in `.sandbox/journals/`: when to create one, what prior context to read, what to log, and how to leave a resumable handoff"
---

Journal is session memory. It is not a runbook and not generalized reusable learning.

## Default posture

Keep journaling useful, not ceremonial.

- For trivial, isolated Q&A, do the minimum
- For file changes, investigations, multi-step work, or anything likely to survive compaction or handoff, keep a real journal
- If a session starts small and becomes complex, open the journal then and add one catch-up entry

## Session start

1. Ensure `.sandbox/journals/` exists
2. Read the newest journal first
3. If the newest journal looks related, read only the extra journal(s) needed to orient
  - Use a light heuristic: same files, same repo area, same problem, or explicit continuation
4. Decide whether this session needs its own journal file. Create one when any of these are true:
  - work will touch files or state
  - the task is multi-step or investigative
  - prior context matters
5. Default file name: `.sandbox/journals/YYYY-MM-DD-<kebab-description>.md`
  - Keep the slug short and task-specific
  - If that exact name already exists for a different session, append `-2`, `-3`, and so on
  - If a higher-priority instruction defines a different naming scheme, use that scheme and keep the same journal policy
6. If the session is complex or resumed, start with a tiny working summary:
  - current goal
  - most important prior fact or decision
  - immediate next action

## During work

Append an entry only when it would help a future agent or your post-compaction self.

Good reasons to write:
- a decision changed the plan, with why
- evidence confirmed or killed a hypothesis
- you edited non-trivial files, and why
- you hit a dead end worth not repeating
- you uncovered an open question, blocker, risk, or exact next step

Do not write:
- routine browsing or obvious commands
- long transcripts
- generic principles that belong in the prompt or `napkin`
- speculation without an outcome

## Entry shape

Use the smallest format that preserves the signal.

```markdown
## YYYY-MM-DD HH:MM — short summary
- Evidence: `command` -> decisive excerpt
- Decision: what changed, and why
- Files: `path` — why it matters
- Dead end: what failed, and what not to retry
- Next: exact next step
```

Include only the fields that matter. Combine related micro-steps into one entry.

## Reversals and supersession

When you reverse an earlier decision, mark both sides

In the new entry:

```markdown
> ⚠️ Supersedes: `YYYY-MM-DD HH:MM — prior summary` (reason)
```

In the old entry:

```markdown
> ⚠️ Superseded by: `YYYY-MM-DD HH:MM — new summary`
```

If updating the old entry is impractical, at least mark the new one clearly.

## Before session end

Before ending a non-trivial session, append a short handoff entry that says:
- where the work stands
- what is verified
- what remains risky or unresolved
- the exact next action

A good handoff should let the next agent continue without re-reading the whole conversation.
