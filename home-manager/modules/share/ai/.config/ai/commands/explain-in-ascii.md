---
description: Generate Markdown visual explanations with ASCII diagrams for systems, code changes, plans, data, and technical concepts. Use for terminal-friendly diagrams, architecture overviews, diff or plan reviews, project recaps, and other text-first visual explanations.
---

Generate Markdown documents that explain systems, code changes, plans, data, and technical concepts using ASCII diagrams and plain text structure. Use this command when the user wants a repo-friendly, copy/paste-friendly, terminal-readable visual explanation.

## Input

$ARGUMENTS

## Delivery rules

- The final output must be a Markdown file, not HTML.
- Prefer ASCII diagrams over Mermaid, SVG, canvas, or image output.
- Write files to `.sandbox/diagrams/YYYY-MM-DD-description.md`. Use descriptive filenames ending in `.md`.
- Keep the document self-contained: all explanation, legend, assumptions, and diagram labels live in the Markdown file.
- Put every ASCII diagram inside fenced code blocks.
- If a table would become unreadable in plain Markdown, replace it with a compact list plus an ASCII matrix or diagram rather than switching to HTML.

## Choose the representation

| Content | Default representation |
|---|---|
| Flowchart, pipeline, decision tree | Box-and-arrow ASCII diagram |
| Sequence or request lifecycle | Lifeline-style ASCII sequence |
| Hierarchy, ownership, directory shape | Indented tree with connectors |
| Architecture or topology | Bounded boxes with labeled links |
| State machine | Boxes with named transition arrows |
| Comparison, audit, status matrix | Markdown table, or ASCII matrix when grouping matters visually |
| Timeline or rollout plan | Vertical ASCII timeline |
| Diff or implementation plan review | Sectioned Markdown with small ASCII dependency or flow sketches |

## ASCII diagram invariants

- Assume monospace rendering and preserve alignment.
- Keep diagrams roughly within 100 columns unless the user explicitly asks for a wider layout.
- Use plain ASCII characters by default: `-`, `|`, `+`, `>`, `<`, `/`, `\\`, `[ ]`, `( )`. Only use Unicode box-drawing when the user asks or the target is known to support it.
- Keep labels short inside diagrams; move longer explanations below the diagram.
- Show direction clearly with arrows and connection labels.
- For complex systems, use one overview diagram plus smaller focused sub-diagrams instead of one sprawling block.
- Include a legend when symbols, numbering, or edge styles are not obvious.
- Prefer orthogonal lines over diagonal art; they survive editing and diffing better.
- When line crossings make the layout hard to read, split the content into numbered stages or separate views.
- If the diagram references files, components, or steps, use exact names from the source material.

## Markdown layout invariants

- Start with a one- or two-sentence summary of the main idea.
- Use headings so each diagram has context.
- Follow each diagram with a short explanation of what the reader should notice.
- Use bullets for assumptions, constraints, and takeaways.
- Keep code, paths, commands, and identifiers in backticks.
- Make the file easy to review in git: stable ordering, short wrapped prose, no decorative filler.

## Final checklist

Before delivery, verify:

- output is valid Markdown;
- output is written to the requested path;
- every diagram is inside a fenced code block;
- alignment survives normal monospace rendering;
- the main idea is obvious from the first screenful;
- long labels are explained outside the diagram;
- the document is self-contained and does not rely on HTML, CSS, or JS.
