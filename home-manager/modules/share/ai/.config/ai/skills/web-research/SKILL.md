---
name: web-research
description: Use when the user says "search internet", "look it up", or asks for current web information on any topic
---

# Web Research Skill

Structured approach to web research using parallel subagents, file-based communication, and systematic synthesis.

## When to Use

- User asks to search the internet or look something up
- Information may be outdated in training data (current events, versions, prices)
- Comparative analysis across multiple sources

**When NOT to use:**
- Single well-known fact (just answer directly)
- Question answerable from codebase/local files

## Research Process

### Step 1: Plan

Create `.sandbox/research/YYYY-MM-DD-[topic]/research_plan.md` with:
- Main question
- 2–5 non-overlapping subtopics
- How results will be synthesized

**Subtopic count:**
- Simple fact-finding: 1–2
- Comparative: 1 per element (max 3)
- Complex: 3–5

### Step 2: Delegate to Subagents

Spawn one `web-search-researcher` subagent per subtopic (up to 3 in parallel):

```
Research [SPECIFIC TOPIC]. Use web_search to gather information.
Save findings to .sandbox/research/YYYY-MM-DD-[topic]/findings_[subtopic].md.
Include key facts, relevant quotes, and source URLs.
Use 3–5 searches maximum.
```

### Step 3: Synthesize

1. `ls .sandbox/research/YYYY-MM-DD-[topic]/` to confirm findings files exist
2. `read` each findings file
3. Write a response that directly answers the question, integrates all subtopics, and cites URLs
4. Optionally write `research_report.md` if user requested a document

## Available Tools (pi environment)

| Tool | Use for |
|------|---------|
| `write` | Save research plan and report |
| `read` | Read local findings files |
| `ls` / `find` | List files in research folder |
| `bash` | Anything else (move, mkdir, etc.) |
| `web-search` | Direct single searches (skip subagent for simple lookups) |

## Best Practices

- Write `research_plan.md` before spawning any subagent
- Each subagent gets a distinct, non-overlapping scope
- 3–5 searches per subtopic is enough — don't over-research
- Subagents communicate via files, not return values
