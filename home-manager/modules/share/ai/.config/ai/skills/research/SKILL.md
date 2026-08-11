---
name: research
description: Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent.
disable-model-invocation: true
---

1. Investigate the question against **primary sources** — official docs, source code, specs, first-party APIs — not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown file, citing each claim's source, 
3. Save it in `.sandbox/researches/YYYY-MM-DD-JIRA-XXXX-description.md` where:
  - YYYY-MM-DD is today's date
  - JIRA-XXXX is the ticket number (omit if no ticket)
  - description is a brief kebab-case description
  - Examples:
    - with ticket: `2025-01-08-JIRA-1478-parent-child-tracking.md`
    - without ticket: `2025-01-08-improve-error-handling.md`
