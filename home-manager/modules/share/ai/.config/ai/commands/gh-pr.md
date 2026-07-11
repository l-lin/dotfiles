---
description: Create GitHub Pull Request with `gh` CLI.
---

Create a GitHub PR via `gh` CLI with a clear, reviewer-friendly description. Follow the `clear-writing` skill for the prose.

## Workflow

1. Find the Jira ticket in the branch name (e.g. `FEAT-456-add-auth`).
2. Invoke the `jira` skill, then run `jira issue view <JIRA_KEY>`.
3. Draft the description with the template below.
4. Create the PR as a draft: `gh pr create --draft --title "<type>(<JIRA_KEY>): <desc>" --body-file -` (paste the description).

## PR Description Template

```
## [JIRA-123](https://atlassian.net/browse/JIRA-123)

One paragraph: what this PR does and why.

### Diagram

Optional. Add only if a picture clarifies the change (flow, sequence, component map).
Use a `mermaid` block, or ASCII for something simple. Skip this section otherwise.

### Notes for reviewers

- Focus areas: where reviewers should look most carefully
- Trade-offs and rejected alternatives
- Follow-up items
```

## Conventions

- **Title**: conventional commits style — `<type>(<scope>): <description>`
- **Summary**: state what and why; skip what the code does, the diff shows that
- **Diagram**: add one only when it clarifies; mermaid preferred, ASCII for simple cases
- **Notes**: flag non-obvious decisions, edge cases, and where reviewers should focus
- **Concise**: no one wants to read wall of texts, be concise
