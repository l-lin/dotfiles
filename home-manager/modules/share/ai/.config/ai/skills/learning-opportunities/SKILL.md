---
name: learning-opportunities
description: Use when finishing a feature or bugfix with new files, modules, schema changes, refactors, design decisions, or unfamiliar patterns, or when the user asks to learn, practice, understand the reasoning, or says "teach me", "help me understand", "walk me through", or "quiz me".
---

# Learning Opportunities

## Overview

Turn recent work into retained knowledge, not just output. Offer a short exercise only when the work created something worth understanding.

For the learning-science rationale, see [principles.md](./references/principles.md).

## When to Use

Use after:
- new files or modules
- schema changes
- refactors or architecture decisions
- unfamiliar libraries, frameworks, or debugging paths
- user questions like `why`, `how`, `teach me`, `help me understand`, `walk me through`, `quiz me`, or `give me an exercise`

Do not use if:
- the user already declined this session
- the user already completed 2 exercises this session
- the user clearly wants execution only

## Offer

Ask once, briefly:

`Would you like a quick 10-15 minute learning exercise on [topic]?`

If the user declines, do not offer again this session.

## Hard-stop rule

After any exercise prompt, end the message immediately and wait.

Allowed after the question:
- `(Take your best guess, wrong predictions are useful data.)`
- `(Or we can skip it.)`

Do not add:
- hints
- sample answers
- stacked questions
- any teaching content after the pause point

Use this pause pattern:

> **Your turn:** What do you think happens when [specific scenario]?
>
> (Take your best guess, wrong predictions are useful data.)

## Exercise patterns

Pick one:
- **Prediction -> Observation -> Reflection**
- **Generation -> Comparison**
- **Trace the path**
- **Debug this**
- **Teach it back**
- **Retrieval check-in**

## Facilitation rules

- Ask one question at a time.
- Prefer sending the user to real files over pasting long snippets.
- Start with precise file and line guidance, then reduce scaffolding as familiarity grows.
- After the user answers, connect their thinking to the real code path or behavior.
- Be direct when the user is wrong. Name the mismatch, explain why, then continue.
- Do not credit understanding the user did not actually express.
- Keep exercises to 10-15 minutes unless the user asks for more.
