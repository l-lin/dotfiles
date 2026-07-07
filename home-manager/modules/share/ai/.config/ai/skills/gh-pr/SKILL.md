---
name: gh-pr
description: Use when creating a GitHub Pull Request with `gh` CLI.
disable-model-invocation: true
---

# gh-pr

Create a GitHub PR via `gh` CLI with a structured, reviewer-friendly description.

## Workflow

1. Determine the Jira ticket from the branch name (e.g. `FEAT-456-add-auth`).
2. Invoke the `jira` skill then run `jira issue view <KEY>`.
3. Draft the PR description using the template below.
4. Create the PR as draft: `gh pr create --draft --title "<type>(<scope>): <desc>" --body-file -` (paste the description).
5. Assign reviewers if appropriate.

## PR Description Template

```
## [JIRA-123](https://atlassian.net/browse/JIRA-123)

One-paragraph description of what this PR does and why.

### Architecture / Flows

Diagrams (mermaid, ASCII, or links) showing key design decisions.
Use `mermaid` code blocks for flowcharts, sequence diagrams, or component maps.

### Notes for reviewers

- Focus areas: where reviewers should look most carefully
- Trade-offs considered and rejected
- Test coverage notes
- Follow-up items
```

## Conventions

- **Title**: Conventional commits style — `<type>(<scope>): <description>`
- **Summary**: What + why, not what the code does (reviewers read the diff for that)
- **Diagrams**: Mermaid preferred; ASCII acceptable for simple flows
- **Notes**: Call out non-obvious decisions, edge cases, and where to focus review effort
