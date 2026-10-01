Generate illustrated HTML zines that explain systems, code changes, plans, data, and technical concepts through short panels, concrete examples, and plain-language captions. Use this format when the user asks for a zine: a small, readable publication, not a dashboard or slide deck.

## Delivery rules

- Write a complete, self-contained HTML document to `.sandbox/diagrams/YYYY-MM-DD-description-zine/index.html`, unless the user specifies another path.
- Embed all CSS, illustrations, and quiz JavaScript. Use system fonts and inline SVG or CSS drawings; require no CDN, external assets, or network access.
- Open the generated zine in the browser when available. Report when browser verification is unavailable.
- Make the zine readable both on screen and when printed. A PDF or foldable booklet is not required unless requested.
- Include an in-page quiz with exactly five multiple-choice questions and immediate answer feedback.
- Apply this reference directly; do not inherit the HTML reference's Mermaid or slide requirements.

## Plan the story

Before writing HTML, identify the audience, the central question, and the source facts. Map those facts to a short sequence of numbered pages; add pages rather than omit essential behavior or caveats.

| Page role | What to show |
|---|---|
| Cover | A specific title, the central question, and one illustration that introduces the idea |
| Mental model | The main parts and their relationships, with a small labeled drawing |
| Worked example | One concrete input moving through the system in numbered panels |
| Complication | A failure case, boundary condition, or tradeoff and its consequence |
| Takeaway | A compact reference diagram and the few rules the reader should remember |
| Knowledge check | Five questions that test the explanation, with answer feedback |

Combine roles for a small topic or split them for a complex one. Do not force a fixed page count. Introduce the main idea on the cover, not after several pages of setup.

## Panel and illustration rules

- Give each panel one teaching job. Pair a drawing with a short caption explaining what the reader should notice.
- Make reading order explicit with page numbers, panel numbers, and labeled arrows. Match DOM order to visual order.
- Use concrete examples before abstract rules. Carry the same example through successive panels where possible.
- Prefer small inline SVG diagrams, annotated code fragments, and simple comic-style scenes over dense architecture charts.
- Use characters, speech bubbles, and visual metaphors only when they clarify behavior. Label the real components and state where an analogy stops applying.
- Preserve exact source identifiers, directions, conditions, and failure behavior. Distinguish verified facts from assumptions.
- Avoid decorative illustrations that compete with the explanation. Split crowded diagrams into several panels instead of shrinking their labels.
- Make the explanation understandable without the illustration alone: include visible captions and accessible descriptions for meaningful SVGs.

## Layout and style invariants

- Use a light paper-like background, dark ink, and at most two accent colors. Keep contrast strong and meaning independent of color.
- Use an editorial zine style: bold headings, bordered panels, generous margins, and occasional handwritten-style annotations rendered as readable text.
- Keep body text selectable. Use semantic headings, sections, lists, figures, and captions; put code and identifiers in `<code>`.
- Use CSS custom properties for the palette and spacing. Use system font stacks, with monospace for code.
- Use a centered, bounded reading width. Show panels in a small grid on wide screens and a single column on narrow screens.
- Do not use fixed viewport-height pages, carousels, or scroll hijacking. Let readers scroll naturally.
- Prevent overflow with `min-width: 0` on grid/flex children, wrapping for long identifiers, and screen-only scroll containers for wide code.
- Size illustrations responsively with SVG `viewBox`. Keep labels readable on a narrow screen and in print.
- Avoid animation unless it explains a change; respect `prefers-reduced-motion`.

## Print rules

- Include `@media print` styles and sensible `@page` margins. Support ordinary portrait A4 and Letter paper without requiring background printing.
- Start each numbered zine page on a new printed page with `break-before: page`, except the cover. Keep panels together with `break-inside: avoid` where they fit.
- Allow long content to continue onto another sheet rather than clipping it or shrinking all text to fit.
- Remove navigation and interactive controls from print. Expand any explanatory content hidden behind disclosure controls.
- Print the quiz questions and choices, followed by a separate answer key with explanations. Hide that answer key on screen until requested.
- Ensure borders, arrows, and labels remain clear in grayscale. Do not rely on colored backgrounds for structure.

## Quiz requirements

- Use exactly five medium-difficulty multiple-choice questions about the explanation's behavior, sequence, tradeoffs, or failure cases.
- Avoid naming trivia, gotchas, and questions answerable without understanding the topic.
- Make distractors plausible. Balance specificity and vary option lengths so correct answers do not stand out.
- Use labeled radio groups or buttons that work with keyboard navigation. Announce feedback with an accessible live region.
- After a choice, show whether it was correct, explain why, and point back to the relevant page or panel.
- Keep the core explanation readable without JavaScript; JavaScript should only enhance the quiz.

## Final checklist

Before delivery, verify:

- the HTML document exists at the requested path and works offline;
- the central question and main idea are clear on the cover;
- every panel has a clear reading order and a useful caption;
- source facts, identifiers, assumptions, and caveats are preserved;
- no content overflows at narrow mobile or normal desktop widths;
- meaningful illustrations have accessible descriptions, and controls work with the keyboard;
- all five quiz questions give correct feedback, with no console errors;
- print preview preserves content, page order, legible diagrams, and the quiz answer key;
- the result reads like an illustrated explanation, not a decorated wall of text.
