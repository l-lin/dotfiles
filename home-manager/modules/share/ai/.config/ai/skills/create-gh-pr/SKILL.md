---
name: create-gh-pr
description: Use when creating GitHub Pull Request.
disable-model-invocation: true
---

Create a PR description with `gh` CLI with a clear, reviewer-friendly description.

## Workflow

1. Find the Jira ticket in the branch name (e.g. `FEAT-456-add-auth`)
2. Invoke the `jira` skill to fetch the Jira url
3. Load `clear-writing` skill and use simple words
4. Draft the description with the template below
5. Create the PR as a draft or update PR description

## PR Description Template

```
## [JIRA-123](https://atlassian.net/browse/JIRA-123)

Description of what this PR does and why. Use bullet points.

### Diagram

Add picture to clarify the change (flow, sequence, component map).
Use a `mermaid` blocks.

### Notes for reviewers

- Focus areas: where reviewers should look most carefully
- Trade-offs and rejected alternatives
- Follow-up items
```

## Conventions

- **Title**: conventional commits style — `<type>(JIRA-123): <description>`
- **Summary**: state what and why; skip what the code does, the diff shows that
- **Diagram**: add only when it clarifies; mermaid preferred
- **Notes**: flag non-obvious decisions, edge cases, and where reviewers should focus
- **Concise**: no one wants to read wall of texts, be concise
