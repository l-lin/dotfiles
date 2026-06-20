---
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree.
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time using `ask-user-question` tool.

If a question can be answered by exploring the codebase, explore the codebase instead.

After plan approval, write the plan to `.sandbox/plans/YYYY-MM-DD-JIRA-XXXX-description.md` where:

- YYYY-MM-DD is today's date
- JIRA-XXXX is the ticket number (omit if no ticket)
- description is a brief kebab-case description
- Examples:
  - with ticket: `2025-01-08-JIRA-1478-parent-child-tracking.md`
  - without ticket: `2025-01-08-improve-error-handling.md`

$ARGUMENTS
