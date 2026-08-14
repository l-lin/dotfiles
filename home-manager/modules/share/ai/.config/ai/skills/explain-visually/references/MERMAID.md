Generate a Markdown document that explains the user's topic with Mermaid diagrams and short supporting prose. Use this when the requested output should stay in Markdown but benefit from structured diagrams.

## Delivery rules

- The final output must be Markdown, not HTML.
- Put every Mermaid diagram inside fenced code blocks with the `mermaid` language tag.
- Write files to `.sandbox/diagrams/YYYY-MM-DD-description.md`. Use descriptive filenames ending in `.md`.
- Keep the document self-contained: include context, assumptions, legends, and takeaways in the Markdown file.
- Add only the Mermaid diagrams needed to make the explanation clearer than plain prose.
- Prepare a five-question medium-difficulty multiple-choice quiz that tests real understanding of the explanation.
- Do not put the quiz into the Markdown file. Ask it directly with the `ask-user-question` tool after presenting the document.

## Choose the representation

| Content | Default representation |
|---|---|
| Flow, pipeline, decision tree | `flowchart TD` |
| Sequence or request lifecycle | `sequenceDiagram` |
| State machine | `stateDiagram-v2` |
| Hierarchy or ownership | `flowchart TD` with grouped nodes |
| Architecture or topology | `flowchart TD` or a small grouped overview |
| Timeline or rollout | `timeline` when supported, otherwise `flowchart TD` |
| Comparison or status | Markdown table, plus Mermaid only when relationships matter |

## Mermaid diagram invariants

- Keep diagrams readable in raw Markdown and rendered Markdown.
- Prefer one overview diagram plus small focused diagrams over one crowded block.
- Keep node labels short. Move long explanations below the diagram.
- Use exact names from the source material for files, modules, components, and steps.
- Prefer top-down flow unless left-to-right is clearly simpler.
- Avoid crossing edges when a split into multiple diagrams would read better.
- Use subgraphs sparingly, only when grouping materially improves clarity.
- Do not add styling directives unless the user asks for presentation polish.

## Markdown layout invariants

- Start with a one- or two-sentence summary.
- Use headings so each diagram has context.
- Follow each diagram with a short note about what the reader should notice.
- Use bullets for assumptions, constraints, and key takeaways.
- Keep code, paths, commands, and identifiers in backticks.
- Make the file stable in git: no decorative filler, no gratuitous reordering.

## Quiz requirements

Ask the quiz in chat with `ask-user-question` instead of embedding it in the file.

- Use exactly five multiple-choice questions.
- Make them medium difficulty, focused on the substance of the explanation.
- Avoid gotchas, file-name trivia, and questions answerable from a skim.
- Ask one question at a time so you can respond with whether the answer was correct and give brief feedback before moving on.

## Final checklist

Before delivery, verify:

- output is valid Markdown;
- output is written to the requested path;
- every Mermaid diagram is inside a fenced `mermaid` block;
- the main idea is obvious from the first screenful;
- labels match the source material;
- explanations keep the file quiz-free and use `ask-user-question` for the five-question interactive quiz;
- the document is self-contained and does not rely on HTML, CSS, or JS.
