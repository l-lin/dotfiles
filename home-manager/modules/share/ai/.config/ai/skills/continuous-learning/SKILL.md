---
name: continuous-learning
description: "Review a finished session for reusable knowledge, then, with user consent, update shared skills and project AGENTS.md guidance."
---

# Continuous Learning

## 1. Reflect first

Review the conversation and note:
- the goal, approach, and outcome
- key decisions and rejected alternatives
- obstacles, dead ends, and fixes
- patterns that would help again

Ask internally:
1. Is this genuinely new or easy to forget?
2. Will it help in future work?
3. Is it concrete enough to act on?
4. Did the approach actually work?

Skip updates when the lesson is trivial, one-off, too narrow to reuse, or still unverified.

## 2. Classify the learning

Choose one destination for each durable lesson:
- **Skill**: reusable across projects or codebases
- **`AGENTS.md`**: repo-specific rule, workflow, or gotcha
- **Both**: a broad technique plus a project-specific wrinkle
- **Neither**: interesting, but not worth keeping

If nothing survives this filter, stop.

When the destination includes a skill, classify it as one of these types:
- `pattern`
- `pitfall`
- `debugging`
- `tool-usage`
- `domain`

Use that type when naming the skill directory, for example `~/.config/.ai/skills/debugging-postgres-connection-pool/SKILL.md`.

## 3. Pause for consent

Before you create or update any skill or `AGENTS.md` file, ask the user whether they want the continuous-learning update.

Prefer `ask-user-question` when available. Use a simple yes/no choice, for example:

```markdown
📚 Do you want me to capture reusable learnings from this session in skills and `AGENTS.md`?
```

**End your message immediately after the question.**
Wait for the user's answer. If they say no, stop. Do not create or edit anything.

## 4. Update the right artifacts

### 4.1 Skills

- Search existing skills first. Update an existing skill when the new lesson extends it. Create a new skill only when the pattern is distinct.
- Store skills in `.ai/skills/<type>-<short-description>/SKILL.md`.
- Use the `writing-skill` skill to draft or revise skill content.
- Use `clear-writing` for the prose.
- Keep skills general, actionable, and free of project-only details better suited for `AGENTS.md`.

### 4.2 Project `AGENTS.md` files

- Search for every project `AGENTS.md` with `fd -H '^AGENTS\.md$' .`.
- A project can have several `AGENTS.md` files. Update every file whose scope applies to the work, not just the first match.
- Prefer the nearest relevant `AGENTS.md`, and also update broader-scoped files when the rule belongs there too.
- Keep entries durable, specific, and action-oriented. Match each file's local style.
- Do not add session logs, generic system rules, or guidance already covered elsewhere.

## 5. Quality gates

Before saving, verify:
- the lesson matches what actually worked
- the target file is the right scope
- the wording is short, concrete, and human-readable
- no secrets, internal URLs, PII, or one-off noise slipped in

## 6. Report back

After the updates, tell the user:
- which skill files you created or revised
- which `AGENTS.md` files you updated
- a one-line summary of the captured learning
- your confidence or any follow-up checks still needed
