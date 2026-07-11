---
name: llm-wiki
description: Use when initializing a new personal knowledge base (wiki) from the LLM Wiki pattern — a structured markdown repo where the LLM incrementally builds and maintains interlinked pages between raw sources and a persistent wiki layer
disable-model-invocation: true
---

Initialize a personal knowledge base using the LLM Wiki pattern: the LLM reads raw sources, builds a persistent wiki of summaries/entities/concepts/analyses, and keeps it current. You curate sources; the LLM does the bookkeeping.

**Core principle:** The wiki is a compounding artifact — cross-references, contradictions, and synthesis are already done. No embedding-based RAG needed.

## Quick Reference

| Path | Owner | Purpose |
|------|-------|---------|
| `raw/` | Human | Immutable source docs |
| `wiki/` | LLM | Generated pages |
| `AGENTS.md` | Human + LLM | Schema + runbook |
| `wiki/index.md` | LLM | Content catalog |
| `wiki/log.md` | LLM | Activity log |
| `wiki/overview.md` | LLM | Evolving synthesis |

## Initialization

When asked to initialize a wiki, create this structure:

```
.
├── AGENTS.md              # Schema + agent runbook (co-evolved)
├── raw/                   # Immutable sources (human-only writes)
│   ├── specs/             # Technical docs, architecture
│   ├── papers/            # Research papers, whitepapers
│   ├── vendor/            # Vendor docs, product pages
│   └── assets/            # Downloaded images/diagrams
└── wiki/                  # LLM-generated (LLM writes)
    ├── index.md           # Master content index
    ├── log.md             # Append-only activity log
    ├── overview.md        # High-level synthesis
    ├── summaries/         # One file per ingested source
    ├── entities/          # Systems, vendors, standards, tools
    ├── concepts/          # Technical concepts, patterns, principles
    └── analyses/          # Comparisons, syntheses, deep dives
```

### AGENTS.md

Create with: directory structure + ownership rules, page templates, workflows, conventions, domain considerations. This file turns the LLM from a chatbot into a disciplined wiki maintainer.

### wiki/index.md

Content catalog organized by category. Each entry: link, one-line description, optional metadata.

### wiki/log.md

Append-only: `## [{date}] {action} | {title}`. Actions: `ingest`, `query`, `lint`, `update`, `create`.

## Page Templates

| Type | For | Key fields |
|------|-----|------------|
| Entity | Systems, vendors, standards, tools | type, status, overview, key facts, relevance, related, sources |
| Concept | Patterns, principles, techniques | category, definition, why it matters, how it works, trade-offs, examples, related, sources |
| Summary | One per ingested source | source path, type, ingested date, TL;DR, key takeaways, detailed notes, questions raised, connections |
| Analysis | Comparisons, syntheses, decision matrices | type, dates, question, methodology, findings, recommendations, confidence level, sources |

## Workflows

| Workflow | Steps |
|----------|-------|
| **Ingest** | Read source → discuss takeaways → create summary → update/create entity + concept pages → cross-reference → update index + overview → log |
| **Query** | Read index.md → read relevant wiki pages (not raw) → synthesize with citations → consider filing as analysis → log |
| **Lint** | Check orphans, stale claims, contradictions, missing pages, missing cross-refs, data gaps |

## Conventions

- **File naming:** lowercase, hyphen-separated (`foobar-standard.md`)
- **Links:** relative markdown — `[FOOBAR](../entities/foobar-standard.md)`
- **Dates:** ISO 8601 (`2026-04-14`)
- **Citations:** every claim traces to a source summary

## Reference

Full pattern: [./references/LLM-WIKI.md](./references/LLM-WIKI.md).
