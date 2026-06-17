---
description: Initialize the current repository as a minimal Open Knowledge Format (OKF v0.1) bundle.
---

# Open Knowledge Init

Input: "$ARGUMENTS"

Use this command to scaffold a brand-new repository as a minimal Open Knowledge Format bundle rooted at the current directory.

## Initial workflow

When this command is invoked:

1. Treat `$ARGUMENTS` as optional seed text for the bundle's subject, title, and one-line description.
2. Inspect the current directory before writing anything:
   - Check whether `.git/` exists. If not, run `git init`.
   - List markdown files with `fd -H -e md . .`.
   - For every non-reserved markdown file, verify whether it already has YAML frontmatter with a non-empty `type`.
3. If the repo already contains non-reserved markdown files that would make root-level OKF conformance fail, STOP and explain exactly which files are in the way. Offer these options and wait for the user's choice:
   - convert those files into OKF concept documents
   - initialize the bundle in a dedicated subdirectory instead
4. If the repo is clean enough to proceed, derive the initial bundle metadata:
   - Prefer the user's `$ARGUMENTS` when provided.
   - Otherwise derive a sensible title from the current directory name.
   - If the one-line description would be a guess, ask the user before writing files.

## OKF rules to follow

Scaffold the repository to match OKF v0.1:

- `index.md` and `log.md` are reserved filenames.
- Root `index.md` may include frontmatter, but only to declare `okf_version: "0.1"`.
- Every non-reserved `.md` file must contain parseable YAML frontmatter with a non-empty `type` field.
- Use standard markdown links. Prefer bundle-relative links that start with `/`.
- Use ISO 8601 datetimes for concept `timestamp` fields.
- Use `YYYY-MM-DD` headings in `log.md`, newest first.
- Do not invent a fixed type registry. Use clear, descriptive type names.

## Minimal scaffold

Create only this structure unless the user asks for more:

```text
.
├── index.md
├── log.md
└── concepts/
    ├── index.md
    └── project-overview.md
```

## File templates

Fill these templates with concrete values. Do not leave placeholders in the final files.

### `index.md`

```markdown
---
okf_version: "0.1"
---

# <Bundle Title>

* [Core Concepts](concepts/) - Foundational knowledge for this bundle.
* [Update Log](log.md) - Chronological history of bundle changes.
```

### `log.md`

```markdown
# Directory Update Log

## YYYY-MM-DD
* **Initialization**: Created the initial OKF bundle scaffold.
```

### `concepts/index.md`

```markdown
# Core Concepts

* [Project Overview](project-overview.md) - Starting point for the bundle's purpose, scope, and structure.
```

### `concepts/project-overview.md`

```markdown
---
type: Reference
title: Project Overview
description: High-level purpose, scope, and structure of this knowledge bundle.
tags: [overview]
timestamp: YYYY-MM-DDTHH:MM:SSZ
---

# Purpose

Describe the system, team, or domain this bundle explains.

# Scope

State what belongs in this bundle and what does not.

# Structure

This bundle starts with [Core Concepts](/concepts/index.md). Add new concept documents as the knowledge graph grows.

# Next Concepts To Add

- A glossary of domain terms
- Key datasets, APIs, or services
- Runbooks and playbooks the agents will need
```

## Writing requirements

- Keep the scaffold minimal and useful.
- Use `index.md` as the landing page. Do not create a plain `README.md` unless it is also a valid OKF concept document with frontmatter and `type`.
- Write short descriptions that help both humans and agents scan the tree quickly.
- If the user already told you the repo's domain, reflect it in the title, overview, and suggested next concepts.
- If the domain is still unknown, keep the starter concept generic rather than making up fake business details.

## Verification

After writing the scaffold:

1. Read back every file you created.
2. Confirm that each non-reserved markdown file you created has YAML frontmatter and a non-empty `type`.
3. Confirm that reserved files follow the expected OKF shapes:
   - `index.md` files act as directory listings
   - `log.md` uses ISO date headings and chronological entries
4. Summarize what was created and call out any existing files that still prevent full repo-level OKF conformance.

## Do not

- Do not overwrite unrelated files without explicit user approval.
- Do not create extra directories, CI, licenses, or code unless the user asks.
- Do not add arbitrary required metadata beyond OKF's `type` requirement.
- Do not pretend the repo is conformant if existing markdown files still violate the spec.
