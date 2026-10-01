Generate illustrated HTML zines that explain systems, code changes, plans, data, and technical concepts through short panels, concrete examples, and plain-language captions. Make them feel like independent publications assembled with ink, scissors, tape, and a photocopier, not dashboards, slide decks, or polished marketing pages.

## Delivery rules

- Write a complete, self-contained HTML document to `.sandbox/diagrams/YYYY-MM-DD-description-zine/index.html`, unless the user specifies another path.
- Embed all CSS, illustrations, and reader/quiz JavaScript. Use system fonts and inline SVG or CSS drawings; require no CDN, external assets, or network access.
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

## Art direction: underground print, not a UI kit

Draw from early *2600*, *Principia Discordia*, and DIY punk zines. Borrow their visual language, not their logos, copyrighted artwork, or unrelated slogans. For each new zine, randomly choose one dominant influence and use the others as accents. Do not always default to the same influence or let the topic dictate the same style every time; adapt the chosen style to the explanation.

| Influence | Visual vocabulary | Where it helps |
|---|---|---|
| Early *2600* | Compact masthead, issue/date line, strong black rules, typewriter text, technical schematics, dense but ordered editorial columns | Systems explanations, field notes, annotated code, troubleshooting |
| *Principia Discordia* | Uneven scale, antique-looking serif headings, stamps, marginalia, found-document collage, small symbols and unexpected juxtapositions | Reframing a mental model, exposing contradictions, highlighting exceptions |
| Punk zines | Cut-paper headlines, black-and-white halftones, torn edges, tape, marker circles, high-contrast silhouettes, deliberately uneven alignment | Covers, decisive takeaways, failure cases, urgent annotations |

Make the handmade character visible in the composition, not just in a paper-colored background. Use a few recurring devices: a masthead, cut-paper title strips, diagram style, margin notes, and folios. Give the cover one large visual anchor, such as a bespoke diagram or silhouette; an oversized title alone is not an illustrated cover.

Vary the page rhythm. Alternate an open illustrated page with a denser field-note spread, a step-by-step comic, or a full-width annotated diagram. Use asymmetry and changes in scale to guide attention, while preserving a clear reading order. Do not repeat an identical card grid on every page.

Keep the factual narration direct. Put eccentricity into framing, illustration, and typography, not invented quotations, fake provenance, or obscure jokes. Marginalia must add a clarification, caveat, or useful cross-reference. Issue labels and stamps must describe the topic or document, not imply an official status it does not have.

### Choose a fresh light-paper edition

At generation time, randomly choose a palette from the table, independently of the dominant influence. These are starting points, not fixed templates; vary the masthead typography, cover composition, and two or three recurring handmade devices as well. If a previous zine is available in the current context, choose a different combination. No persistent history is required, and random selection may occasionally repeat.

| Palette | Paper | Ink | Spot-color accents |
|---|---|---|---|
| Cream and vermilion | `#fff8ee` | `#292522` | Vermilion `#b43c2e`, ochre `#8a6500` |
| Mint field notes | `#f2faf5` | `#24332d` | Pine `#28654b`, rust `#a74430` |
| Powder-blue press | `#f3f8fd` | `#26313d` | Cobalt `#345da8`, raspberry `#a53660` |
| Lavender marginalia | `#faf5ff` | `#332b3e` | Plum `#794391`, teal `#246d70` |
| Rose newsprint | `#fff5f3` | `#392c2a` | Brick `#a63e35`, slate blue `#48648a` |

Keep the selected palette and visual devices consistent throughout that zine, including reader controls and quiz feedback. Choose once when generating the document, not on reload or page navigation. Verify contrast for actual text/background pairs; a palette entry alone does not guarantee accessibility.

### Practical visual treatments

- Vary the masthead between condensed sans-serif, bold serif, and typewriter lettering to suit the chosen influence. Pair it with readable editorial text and monospace technical notes; use no more than three system-font families.
- Build cut-paper headlines from selectable dark text on rectangular light-paper strips. Vary the strip lengths and alignment rather than styling every letter separately.
- Use hard offset shadows, double rules, dashed cut lines, and occasional irregular SVG borders instead of soft shadows, rounded cards, or glass effects.
- Create original inline SVG line art, crosshatching, stippling, silhouettes, and halftone patterns. Draw components as physical objects or annotated schematics when that makes the behavior easier to understand.
- Suggest photocopier wear with sparse speckles, broken edge marks, or a low-opacity CSS/SVG texture confined to blank areas. Never put noise over body text, code, or diagram labels.
- Rotate a few decorative scraps or short labels by roughly 1–2 degrees. Keep paragraphs, code, diagrams, and interactive controls level. Leave space around rotated elements so they do not collide or overflow.
- Use tape tabs, marker underlines, circled steps, or rubber-stamp callouts sparingly. Each page needs a dominant feature, not every effect at once.
- Keep decorative SVGs out of the accessibility tree with `aria-hidden="true"`; keep meaningful illustrations labeled. Decorative layers must not intercept clicks or obscure focus indicators.

## Panel and illustration rules

- Give each panel one teaching job. Pair a drawing with a short caption explaining what the reader should notice.
- Make reading order explicit with page numbers, panel numbers, and labeled arrows. Match DOM order to visual order.
- Use concrete examples before abstract rules. Carry the same example through successive panels where possible.
- Prefer small inline SVG diagrams, annotated code fragments, and simple comic-style scenes over dense architecture charts.
- Use characters, speech bubbles, and visual metaphors only when they clarify behavior. Label the real components and state where an analogy stops applying.
- Preserve exact source identifiers, directions, conditions, and failure behavior. Distinguish verified facts from assumptions.
- Let illustrations carry the explanation: show movement, contrast, dependencies, or consequences rather than adding generic clip art. Keep collage and texture subordinate to those teaching jobs. Split crowded diagrams into several panels instead of shrinking their labels.
- Make the explanation understandable without the illustration alone: include visible captions and accessible descriptions for meaningful SVGs.

## Layout and style invariants

- Keep the entire screen presentation light: use white or lightly tinted paper for the browser canvas, pages, panels, navigation, and quiz. Use near-black ink and at most two spot-color accents. No dark backgrounds, dark-mode variants, or reversed white-on-dark headline blocks; use outlines, hatching, or pale accent fills for emphasis instead. Keep contrast strong and meaning independent of color. Set `color-scheme: light` so native controls also stay light.
- Create hierarchy through oversized headlines, compact subheads, readable body text, and small folios. Keep margins, gutters, and panel gaps compact; use blank space to separate ideas, not to pad out pages. Avoid large empty cover areas and stretched panels.
- Keep body text selectable. Use semantic headings, sections, lists, figures, and captions; put code and identifiers in `<code>`.
- Use CSS custom properties for palette, spacing, borders, and hard shadows. Use system font stacks, with monospace for code. Keep body text at least `1rem` on screen, with comfortable line height and roughly 45–75 characters per line.
- Use the available desktop width for a two-page spread, bounded only to keep text and diagrams readable. Mix full-width illustrations, unequal columns, inset notes, and occasional bordered panels within each page; collapse to one page on narrow screens. Use grid spans rather than absolute positioning for primary content.
- Keep visual and DOM reading order aligned. Do not use CSS columns for sequential panels or rearrange content with `order`; put margin notes next to the passage they explain.
- Avoid dashboard conventions: no repeated rounded cards, pill-badge collections, gradient hero banners, stock icons, or uniform tile grids. Use publication details such as running headers, section marks, and page numbers instead.
- Aim to fit a desktop spread within the available viewport, but never force a fixed page height, clip content, or shrink text to achieve it. Allow natural vertical scrolling for long pages; do not intercept wheel or touch scrolling.
- Prevent overflow with `min-width: 0` on grid/flex children, wrapping for long identifiers, and screen-only scroll containers for wide code.
- Size illustrations responsively with SVG `viewBox`, but check label sizes after scaling. A `16px` SVG label rendered at half scale is only `8px`; the declared font size does not prove readability. Keep rendered diagram labels at least `1rem` on screen and `10pt` in print.
- At 375px viewport width, redraw wide diagrams as vertical steps or split them into smaller panels rather than shrinking labels. An equivalent narrow-screen diagram must preserve identifiers, branches, arrow direction, and captions.
- If separate mobile and desktop diagrams are needed, show only one at each breakpoint, including in the accessibility tree. Set the print variant explicitly so screen breakpoints do not select it by accident.
- Avoid animation unless it explains a change; respect `prefers-reduced-motion`.

## Two-page reader and navigation

- With JavaScript enabled, show one active spread: consecutive pages side by side, starting with pages 1–2, then 3–4. Pair the cover with the next page instead of reserving an empty facing page. If the final page is unpaired, let it use the available width without a blank placeholder.
- Use a two-column grid with a narrow gutter and a subtle center rule. Balance the amount of content across paired pages when planning the story; do not use fixed aspect ratios or tall minimum heights that create useless space.
- Switch to one active page when two readable pages no longer fit. Navigation then advances one page at a time. On resize, preserve the current reading position by keeping its page visible in the new layout.
- Provide compact Previous/Next buttons, a visible page-range indicator such as “Pages 3–4 of 12,” and a shortcut hint. Disable the relevant button at the first or last page; do not wrap around.
- Within the reader, `j` advances to the next spread; `k` returns to the previous spread. On narrow screens, these keys move one page. Register single-letter shortcuts only while keyboard focus is inside the reader, not globally. On initialization, focus the first page heading without scrolling, unless focus is already on an interactive control; readers can use the shortcuts immediately and Tab out normally.
- Ignore shortcuts originating from interactive controls, editable content, or an open dialog, and ignore modified keys and key-repeat events. In particular, arrow keys must still select quiz radio options. Call `preventDefault()` only when a navigation shortcut actually changes the page.
- After navigation, reveal the destination at its top, move focus to its page heading using `tabindex="-1"`, and announce the page range through a polite live region. Keep visible focus styling; avoid animated page turns.
- Keep all pages in source order in the DOM. Hide inactive pages with `hidden` so they are also absent from keyboard navigation and the accessibility tree; never duplicate pages or rebuild quiz controls during navigation. Answers and feedback must survive page changes.
- Without JavaScript, show every page in a normal scrolling document and hide nonfunctional reader controls. JavaScript enhances navigation and the quiz; it must not gate the explanation or answer key.

## Print rules

- Include `@media print` styles and sensible `@page` margins. Support ordinary portrait A4 and Letter paper without requiring background printing.
- Print every page, not just the active spread. Override reader-only `hidden` states in print CSS, reset the spread grid to block flow, and remove reader height/overflow constraints. Start each numbered zine page on a new printed page with `break-before: page`, except the cover. Keep panels together with `break-inside: avoid` where they fit.
- Allow long content to continue onto another sheet rather than clipping it or shrinking all text to fit. Avoid blank sheets and sheets containing only a folio or running header. Keep folios with preceding content; fix accidental spill pages by reducing decorative spacing or reflowing panels, not by dropping below the minimum text size.
- Remove navigation and interactive controls from print. Expand any explanatory content hidden behind disclosure controls.
- Print the quiz questions and choices, followed by a separate answer key with explanations. Hide that answer key on screen until requested.
- Ensure borders, arrows, and labels remain clear in grayscale. Do not rely on colored backgrounds for structure. Reset reversed text to dark ink on white paper so it survives when background printing is off.
- Remove decorative textures and shadows in print. Reset rotated scraps if they threaten page margins; retain the masthead, line art, rules, and typography that give the zine its identity.
- Keep printed body text at least `10pt`. Collapse editorial columns where needed rather than reducing type size to preserve a screen layout.

## Quiz requirements

- Use exactly five medium-difficulty multiple-choice questions about the explanation's behavior, sequence, tradeoffs, or failure cases.
- Avoid naming trivia, gotchas, and questions answerable without understanding the topic.
- Make distractors plausible. Balance specificity and vary option lengths so correct answers do not stand out.
- Use labeled radio groups or buttons that work with keyboard navigation. Announce feedback with an accessible live region.
- After a choice, show whether it was correct, explain why, and point back to the relevant page or panel.
- Keep the core explanation readable without JavaScript. Quiz behavior must remain independent of reader navigation.

## Browser verification workflow

Use an available browser or browser automation tool. Opening the file is not verification. Keep temporary scripts, screenshots, and print exports under the zine's `.sandbox/diagrams/` directory; they are verification artifacts, not required deliverables.

1. Load the local HTML with network access disabled. Confirm that the explanation, illustrations, and quiz work without external assets. Check the browser console for errors.
2. Render at 375px, 768px, and 1440px viewport widths. Check document overflow, clipped content, and overlapping labels. Inspect screenshots at their actual scale, especially diagram text; passing an overflow check does not prove legibility.
3. Try every option in all five quiz questions. Check correctness, explanation, and the page or panel reference, including after changing an answer. Test the answer-key toggle if present.
4. Test Previous/Next buttons and `j`/`k`: verify page pairs, a final unpaired page, first/last boundaries, focus, and page-range announcements. Resize between two-page and single-page views and confirm reading position is preserved. Check that long pages scroll without clipping and quiz answers survive navigation. Use the keyboard to answer questions and operate any answer-key control; confirm reader shortcuts do not interfere with radio options, buttons, or editable fields. Check visible focus and feedback announcements. Disable JavaScript and confirm that every page and the answer key remain available.
5. Preview or export both portrait A4 and Letter with background printing off. Inspect page order, diagrams, panel splits, and the separate answer key. Check for clipping, blank sheets, and folio-only spill pages; legitimate continuation sheets are allowed. PDF generation or a page-count check alone does not prove print quality.
6. Fix failures and rerun the affected checks. State which browser, viewport, interaction, and print checks passed. If a tool or browser is unavailable, name the skipped checks rather than implying they passed.

## Final checklist

Before delivery, verify:

- the HTML document exists at the requested path and works offline;
- the central question and main idea are clear on the cover, with a distinctive masthead and an illustration tied to the topic;
- a freshly chosen influence, light-paper palette, and recurring visual devices give this edition a coherent identity without defaulting to the same look each time;
- all screen surfaces remain light, including the surrounding canvas, reader controls, and quiz; the underground-print influence is visible in typography, composition, and original illustration, not just background color;
- page layouts vary, recurring visual devices hold them together, and texture never reduces legibility;
- every panel has a clear reading order and a useful caption;
- source facts, identifiers, assumptions, and caveats are preserved;
- desktop shows a compact two-page spread, mobile shows one page, and no content overflows or gets clipped;
- buttons and `j`/`k` navigate correctly without interfering with quiz controls, losing answers, or leaving focus on a hidden page;
- meaningful illustrations have accessible descriptions, and controls work with the keyboard;
- all five quiz questions give correct feedback, with no console errors;
- print preview includes all pages regardless of the active spread and preserves content, page order, legible diagrams, and the quiz answer key;
- the result reads like a handmade illustrated publication, not a decorated wall of text or a dashboard with distressed borders.
