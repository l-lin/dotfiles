---
name: journal
description: "Use for non-trivial sessions, after context compaction, and before session end when journal memory would help."
disable-model-invocation: false
---

Journal is session memory. It is not a runbook and not generalized reusable learning.

## Default posture

Keep journaling useful, not ceremonial.

- For trivial, isolated Q&A, do not load journal history and do not create a journal file
- For file changes, investigations, multi-step work, or anything likely to survive compaction or handoff, keep a real journal
- If a session starts small and becomes complex, open the journal then and add one catch-up entry
- Treat journals as compressed handoffs, not as a second copy of the conversation

## Session start

1. Decide first whether the session needs journaling at all
  - Skip it for trivial, isolated Q&A with no likely follow-up
  - Use it when work will touch files or state, the task is multi-step or investigative, or prior context matters
2. If journaling is needed, ensure `.sandbox/journals/` exists
3. Look for related journals. Do not read the newest journal by default
  - Use a light heuristic: same files, same repo area, same problem, or explicit continuation
  - Prefer the most recent matching journal, not merely the most recent journal overall
  - If nothing looks related, read no prior journal
4. When reading a prior journal, start with the latest handoff or the last one or two entries, not the whole file
  - Read more only if that is not enough to orient
5. Decide whether this session needs its own journal file. Create one when any of these are true:
  - work will touch files or state
  - the task is multi-step or investigative
  - prior context matters
6. Default file name: `.sandbox/journals/YYYY-MM-DD-<kebab-description>.md`
  - Keep the slug short and task-specific
  - If that exact name already exists for a different session, append `-2`, `-3`, and so on
  - If a higher-priority instruction defines a different naming scheme, use that scheme and keep the same journal policy
7. If the session is complex or resumed, start with a tiny working summary:
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

Put the handoff at the end of the file so the next agent can read the last entry first.
A good handoff should let the next agent continue without re-reading the whole conversation.
