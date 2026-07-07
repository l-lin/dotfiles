---
name: pickup
description: Resumes work from a previous handoff session which are stored in `.sandbox/handoffs`.
disable-model-invocation: true
---

Input: "$ARGUMENTS"

- If provided: Read the handoff file which contains the instructions for how you should continue.
- If empty: Present the list handoff files in `.sandbox/handoffs` and use `ask-user-question` tool to ask the user which handoff file you need to resume work from.
