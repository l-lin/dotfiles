---
name: plan
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree.
disable-model-invocation: true
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one by one, and make the implementation shape specific enough that a smaller LLM can execute it without drifting. For each question, provide your recommended answer and the main tradeoff.

Ask the questions one at a time using `ask-user-question` tool.

If a *fact* can be found by exploring the codebase, look it up rather than asking me. The *decisions*, though, are mine — put each one to me and wait for my answer.

When writing the final plan, it must include:

- concrete target files or modules
- the types, interfaces, functions, and signatures to add, update, or delete
- why this shape was chosen
- a safe execution order
- any explicit open questions or deferred decisions
- small code skeletons or focused snippets when signatures alone would leave dangerous ambiguity, especially for new abstractions, tricky edits, or high handoff risk
- for non-trivial work, include the verification approach

Then write the final plan to `.sandbox/plans/YYYY-MM-DD-JIRA-XXXX-description.md` where:

- YYYY-MM-DD is today's date
- JIRA-XXXX is the ticket number (omit if no ticket)
- description is a brief kebab-case description
- Examples:
  - with ticket: `2025-01-08-JIRA-1478-parent-child-tracking.md`
  - without ticket: `2025-01-08-improve-error-handling.md`
