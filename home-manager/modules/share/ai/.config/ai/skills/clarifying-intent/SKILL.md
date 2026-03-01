---
name: clarifying-intent
description: Use when user asks to create, build, design, add, or generate something — especially when the request is vague, underspecified, or the scope is unclear. Use before starting creative work, features, components, or any new functionality.
---

# Clarifying Intent

## Overview

**Don't build what wasn't asked for.** Before starting any creative or generative work, use Socratic questioning to surface the user's real intent, constraints, and success criteria.

**Core principle:** A well-understood problem is half-solved. Questions are cheaper than rework.

## Core Pattern

**STOP. Ask before coding.**

Use `ask-user-question` tool to probe only the dimensions that are actually missing. Don't ask everything — ask what matters.

### Dimensions to Consider

- **Intent / Why** — ask when purpose isn't stated → "What problem does this solve?"
- **Audience / Who** — ask when it affects UX or tone → "Who will use or see this?"
- **Constraints** — ask when tech, time, or style limits are unknown → "Any constraints I should know about?"
- **Success criteria** — ask when "done" is unclear → "What does good look like to you?"
- **Scope** — ask when it could be large or small → "Is this a quick prototype or production-ready?"

### Decision Heuristic

Ask yourself: *"If I'm wrong about X, does the whole thing need to be redone?"*
- Yes → Ask about X
- No → Assume and note assumption

**Target: 2–4 questions max.** More than that is interrogation, not clarification.

## Implementation

```
User: "Add a dashboard component"

Agent thinks:
- Why? (unclear — metrics? navigation? admin?)
- Who? (unknown — end user? internal?)
- Scope? (unknown — full page? widget?)
- Constraints? (assume existing stack unless asked)

Agent asks (using ask-user-question):
1. "What's the main purpose — monitoring data, navigation, or something else?"
2. "Who's the audience — end users, admins, internal team?"
3. "Is this a quick prototype or production-ready?"

→ Block until answered. Then build with full context.
```

## Blocking Rule

**Do not start implementation until answers are in.**

- Don't "start on the obvious parts" while waiting
- Don't make assumptions silently — if you must assume, state them and ask for confirmation
- Don't write placeholder code "to save time"

## Common Mistakes

- **Asking all 5 dimensions every time** — pick only what's missing, read the request
- **Proceeding with assumptions silently** — state assumptions explicitly, ask for confirmation
- **One giant multi-part question** — use `ask-user-question` with separate, focused options
- **Re-asking after user answered** — track answers; don't loop
- **Skipping this for "simple" requests** — simple requests have the most wrong assumptions
