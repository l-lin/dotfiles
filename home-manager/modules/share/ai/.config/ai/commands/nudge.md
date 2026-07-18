---
description: Nudge AI agent with annotations put in the codebase
---

## Core workflow

- Scan diff for comments having `AI!` or `AI?` hints
- For each `AI!` comment, treat the remainder of the line as an inline suggestion and implement the change in the nearby code after reading the entire file
  - Make minimal, local changes aligned with each `AI!` hint
  - Do not make any non-trivial decisions yourself - if instructions are unclear, ask a clarifying question using `ask-user-question` tool
  - If the suggestion cannot be implemented with minimal changes, prompt the user to create a markdown plan instead
- For each `AI?` comment, answer the question using the current context
  - Respond in the format: `<filename>:<line>: <your answer>`
- After updates and answers, delete all `AI!/AI?` comments you processed

## Comment parsing guidance

- Comments in successive lines should be considered a single suggestion/question
- Comments may be related - ensure you understand how the comments relate before acting
- Ignore occurrences in strings or code; only act on actual comments

$ARGUMENTS
