Generate HTML blog tutorials that explain systems, code changes, plans, data, and technical concepts through prose, examples, and visual cues.

## Delivery rules

- Write a complete HTML document to `.sandbox/diagrams/YYYY-MM-DD-description-blog/index.html`, unless the user specifies another path.
- Put the article content, CSS, quiz questions, and answer explanations in the document.
- Allow external fonts, libraries, and assets. State which enhancements require network access.
- Open the article in a browser when available. Opening the file alone does not verify it.
- Include exactly five medium-difficulty multiple-choice questions after the article, with immediate answer feedback.
- Apply this reference directly. Do not inherit `HTML.md` diagram controls or slide rules, or `ZINE.md` pagination and print rules.
- Use normal document scrolling. Do not require print support or PDF output.

## Plan the explanation

Introduce topic-specific terms before using them. Use enough sections to preserve essential behavior, assumptions, and limitations. Do not impose a word count.

Use this sequence as a starting point. Combine or split sections when the topic needs a different structure.

| Section | Teaching purpose |
|---|---|
| Concrete problem | Show a specific situation and state the central question and main idea early |
| First attempt | Show the simplest useful approach and its observable result |
| Worked example | Follow one input or scenario through the important steps |
| Mental model | Explain the components and rules when the example needs them |
| Failure or boundary | Show where the first approach fails and explain the consequence |
| Tradeoffs | Compare relevant alternatives and state when each applies |
| Knowledge check | Test understanding with five questions and answer explanations |

Keep the same example across sections where possible. Introduce concepts when the example needs them, not through a long preliminary glossary.

For non-code topics, use concrete scenarios, data, or decisions instead of artificial code examples. End the explanation before the quiz without a repeated summary.

## Voice and reader engagement

Use original, socratic, conversational prose.

- Address the reader directly when useful.
- Prefer concrete technical situations over general claims.
- Explain why a decision matters before presenting implementation detail.
- Keep paragraphs short, with one topic per paragraph.
- Use frequent brief situational humor.
- Place humorous observations near the technical situation they explain. Keep them shorter than the explanation they support.
- Keep facts, warnings, commands, accessibility labels, and quiz feedback direct.

Use clear section titles that identify the technical question. Preserve exact identifiers and quoted source text.

## Source facts and code examples

- Inspect available source material before explaining its behavior.
- Distinguish verified facts, assumptions, and illustrative examples.
- Use exact source identifiers, conditions, directions, and failure behavior.
- Link source-based claims to relevant files, symbols, or supplied references. Do not invent citations.
- Use short verified source snippets for code topics.
- Test minimal examples when practical. State the test scope and any untested behavior.
- Label pseudocode and untested examples explicitly. Do not present them as verified executable code.
- Show inputs, important state changes, and expected outputs beside examples.
- Label observed outputs separately from expected outputs.
- Include setup and version requirements when the reader needs them to run an example.
- Keep examples focused on the concept. Omit unrelated setup without hiding required dependencies.
- Put selectable code in `<pre><code>` with the language identified.
- Keep annotations outside executable snippets unless a comment explains a necessary design decision.

## Visual cues and demonstrations

Give each visual one teaching purpose. Use annotated code, small diagrams, before/after views, and step markers where they clarify behavior.

- Place each visual beside the passage it explains.
- Give meaningful diagrams a visible caption and an accessible description.
- Use labels, numbered steps, and arrow directions to make reading order clear.
- Preserve the same component names in prose, diagrams, code, and demonstrations.
- Use useful callouts for assumptions, failure cases, or decisions. Avoid repeating paragraphs inside decorative boxes.
- Prefer small focused visuals over one crowded architecture diagram.
- Use original inline SVG or CSS drawings where they explain the topic better than a diagram library.
- Use Pele, not Mermaid.js, for Mermaid-syntax diagrams. Consult its [API](https://pele.run/api), [theming](https://pele.run/theming), and [compatibility](https://pele.run/compatibility) references.
- Allow a hosted Pele dependency or embedded rendering. Match its `--pele-*` colors and fonts to the article.
- Prefer readable static diagrams. Add zoom or expansion only when useful; do not require controls on every diagram.
- Keep text labels readable at their rendered size. Split wide diagrams on narrow screens instead of shrinking labels.

Prefer interactive demonstrations when they expose meaningful state changes. Use step controls, input changes, or before/after switches as the topic requires.

- Define the input, state, transition, and observable result before building the demonstration.
- Show the current state and explain the result of each reader action.
- Include a reset control when the demonstration changes state.
- Keep interactions deterministic unless variability is part of the topic.
- Provide static alternative states with captions for each essential behavior.
- Keep static alternatives available without JavaScript. Do not make an interaction the only explanation of a concept.
- Clearly label simulated behavior. Do not imply that a demonstration executes the source system unless it does.
- Use semantic controls with keyboard access and visible focus indicators.
- Announce important state changes through an accessible live region without moving focus unexpectedly.
- Respect `prefers-reduced-motion`. Do not require animation to understand a transition.

## Editorial layout

Use an annotated essay layout inspired by [Andy Matuschak's article](https://andymatuschak.org/books/). Keep the explanation in one continuous vertical article.

- Use approximately 70% of the available desktop width for the article and 30% for right-side notes.
- Use a shared CSS grid with `minmax(0, 7fr) minmax(0, 3fr)` columns and a compact gutter.
- Align each note's first text line with the first rendered line of its highlighted word, phrase, or sentence.
- Do not align notes with section headings, section tops, or paragraph tops unless the highlight starts there.
- Keep passages and their notes together in DOM order. Use the same column sizes across passage groups.
- Keep article text within the readable line length. Let code and diagrams use the wider article column.
- Use one document scrollbar for both columns. Do not create an independently scrolling notes panel.
- Reserve the right column for comments, clarifications, source details, and brief situational humor where permitted.
- Keep essential facts, instructions, and warnings in the article. Notes must supplement the explanation.
- Leave the right column empty where no note is useful. Do not add notes merely to fill space.
- Put the five-question quiz in the main article column after the explanation.
- Use the Grey palette below. Set the browser canvas, article, and notes column background to `var(--background)`.
- Keep code blocks, controls, and quiz backgrounds light. Use subtle borders or pale fills instead of separate large background panels.
- Set `color-scheme: light` and use dark text with strong contrast.
- Use restrained accents and consistent CSS custom properties for colors, spacing, and fonts.
- Use readable system fonts or hosted fonts with system fallbacks. Use monospace fonts for code.
- Keep body text at least `1rem`, with comfortable line spacing and roughly 45–75 characters per line.
- Use semantic headings, sections, figures, captions, lists, and tables.
- Keep visual order consistent with DOM reading order.
- Avoid repeated card grids, dashboard styling, large empty banners, and decorative illustrations without teaching value.
- Keep primary content in normal flow. Do not impose viewport heights or intercept scrolling.
- Set `min-width: 0` on grid and flex children. Wrap long identifiers where necessary.
- Use local scroll containers for wide code and tables without causing document overflow.
- Collapse to one column when article text and notes no longer fit comfortably. Keep controls usable at 375px width.
- Place each mobile note directly after its related passage. Keep notes visible rather than using drawers or hidden panels.
- Do not duplicate note content for mobile. Preserve note identifiers and links across layout changes.
- Do not use sticky notes or controls that obscure article text.

### Vim scrolling shortcuts

Add embedded JavaScript for document scrolling. Keep the article and notes on the same scrollbar.

| Shortcut | Action |
|---|---|
| `j` | Scroll down by one computed body-text line height |
| `k` | Scroll up by one computed body-text line height |
| `Ctrl+d` | Scroll down by half the current viewport height |
| `Ctrl+u` | Scroll up by half the current viewport height |
| `gg` | Go to the top of the document |
| `G` | Go to the bottom of the document |

- Show a compact shortcut hint and a labeled toggle. Enable Vim scrolling by default; let readers disable it.
- Handle shortcuts while focus is on the document body or noninteractive article content.
- Ignore events from inputs, textareas, selects, buttons, links, disclosures, editable content, and custom interactive controls.
- Ignore shortcuts while a dialog is open, during text composition, or when another handler has prevented the event.
- Accept unmodified lowercase `j`, `k`, and the two-key `gg` sequence.
- Accept uppercase `G`, including Shift+g, without Control, Alt, or Meta.
- Accept `Ctrl+d` and `Ctrl+u` without Shift, Alt, or Meta.
- Do not treat Command as Control. Preserve all other browser shortcuts and native keyboard behavior.
- Prevent the browser's default action only when an enabled shortcut matches in an allowed context.
- Let held scrolling keys repeat. Use immediate scrolling so repeated events do not accumulate animations.
- Complete `gg` only after two separate lowercase `g` presses within 1000 milliseconds. Ignore repeated `g` events.
- Reset the pending `g` after another key, timeout, focus change, pointer action, window blur, or shortcut disabling.
- Do not scroll after the first `g`. Evaluate both presses under the same control and modifier exclusions.
- Compute half-page distance from the current viewport on each event. Clamp scrolling at document boundaries; do not wrap.
- Use `document.scrollingElement` to compute top and bottom positions. Recompute the bottom from current content height on each `G` press.
- Preserve keyboard focus, quiz answers, demonstration state, and note selection while scrolling.
- Keep wheel, touch, arrow-key, Page Up, and Page Down scrolling available. Do not require JavaScript for ordinary reading.
- Test all six scrolling shortcuts, held keys, boundaries, viewport resizing, and the toggle when browser tools are available.
- Test `gg` timeout, intervening keys, focus changes, and held `g`. Check `G` after disclosures change document height.
- Confirm that quiz controls, editable demonstrations, note links, and dialogs retain their native keyboard behavior.

### Grey color scheme

Use the colors from `/Users/louis.lin/perso/github/nvim-grey/colors/grey.lua`. Embed these values in generated HTML; do not require the local theme directory.

```css
:root {
  --background: #f2f2f2;
  --grey-bg-light: #ececec;
  --black: #000000;
  --blue: #1561b8;
  --green: #1C5708;
  --light-green: #dfeacc;
  --light-blue: #dce8f7;
  --light-purple: #eadff3;
  --light-red: #f2d3cd;
  --red: #c4331d;
  --grey: #5e5e5e;
  --light-grey: #e6e6e6;
  --border: #cccccc;
  --highlight: #eeeeee;
  --dark-yellow: #b37f02;
  --yellow: #f9db70;
  --light-yellow: #f9eab3;
  --orange: #a55000;
  --purple: #5c21a5;
  --white: #ffffff;
  --cyan: #007872;
}
```

- Use black for primary text and grey for notes and secondary text.
- Use blue for ordinary links and visible focus outlines.
- Use grey background shades for code surfaces, controls, and subtle selection states.
- Use green on light green for success feedback.
- Use black text on light red for error feedback. Reserve red for markers or text on the main background.
- Keep warning text black on light yellow. Do not use dark yellow for small text without checking contrast.
- Match code highlighting to Grey: bold black keywords, green strings, blue numbers, purple function definitions, and grey comments.
- Use matching pale backgrounds for strings, numbers, and function definitions when syntax highlighting supports them.
- Use orange for macros and purple for instance variables where those categories apply.
- Apply these tokens to diagrams, demonstrations, and quiz feedback. Do not introduce an unrelated library color scheme.
- Use only the colors needed for each element. Do not use every accent merely because it is available.
- Verify actual text/background contrast, including highlighted links and note feedback. Require at least 4.5:1 for normal text.

### Highlighted passages and margin notes

- Connect each note to a highlighted word, phrase, or sentence through unique identifiers and semantic links.
- Use `var(--yellow)` for highlighted word, phrase, and sentence backgrounds, with black text.
- Keep linked passage text black in every state, including visited links. Reserve blue for ordinary links and focus outlines.
- Add an underline or numbered marker. Do not identify note links through color alone.
- Keep passage highlights yellow during hover, focus, and tap. Emphasize matching notes with a light yellow fill and a visible marker.
- Keep all notes visible by default. Hover, keyboard focus, or tap must emphasize the matching passage and note.
- Use inline links rather than block buttons inside prose. Preserve text selection and normal link activation.
- Keep matching emphasis distinct from keyboard focus indicators. Do not move focus or scroll the page on hover.
- Give each note an accessible label and a return link to its source passage.
- Keep note text readable, with at least `1rem` type. Use spacing and subtle rules to distinguish it from article prose.
- Keep links and notes available without JavaScript. Add matching emphasis as an enhancement, not a visibility requirement.
- Verify hover, focus, tap, return links, and mobile note placement when browser tools are available.

### Note placement at the highlighted text

- Measure the actual inline highlight with `getClientRects()`. Use its first nonempty rectangle when the highlight wraps across lines.
- Align the note's first text line to that rectangle's top. Account for note padding, labels, margins, and line height.
- Convert viewport measurements to coordinates relative to the note's containing block. Do not mix viewport and document coordinates.
- Use measured spacing or positioned notes within the right column. Do not use hardcoded offsets or section-level `align-items: start` alone.
- Keep article text in normal flow. Reserve sufficient height for positioned notes so they cannot overlap later sections or the quiz.
- Recalculate after `document.fonts.ready`, viewport resizing, image loading, disclosure changes, and dynamic diagram or demonstration rendering.
- Recalculate after diff wrapping and split/unified changes when this layout is used for PR articles.
- Observe relevant content size changes with `ResizeObserver`. Schedule measurements through `requestAnimationFrame` and avoid observer loops.
- Reset previous placement offsets before measuring. Separate measurement from placement to prevent accumulated spacing and layout drift.
- Resolve note collisions by shortening notes or adding space between their source passages. Preserve facts and remeasure the resulting highlights.
- Do not silently move a note away from its highlight to avoid a collision. Do not clip notes or cover article text.
- Keep notes in readable source order without JavaScript. Restore normal-flow placement when the layout collapses to one column.
- When browser tools are available, compare each note's first text line with its highlight, not merely its section.
- Check multiline highlights, several notes in one section, late font loading, and content changes above the highlighted passage.

## External dependencies and failure behavior

Network access can be required for enhanced content. The base article text, examples, quiz content, and static demonstration alternatives must remain in the HTML.

- List external dependencies and the features they provide.
- Avoid external assets that do not improve the explanation.
- Use versioned dependency URLs where available.
- Show a clear unavailable state when an external enhancement fails. Do not leave an unexplained blank visual or permanent loading message.
- Keep static demonstration alternatives visible when enhancements cannot load.
- Use font fallbacks when hosted fonts fail.
- Keep quiz logic independent of diagram and demonstration libraries.
- Do not claim offline support unless all required assets are embedded and offline checks pass.

## Quiz requirements

Place exactly five medium-difficulty multiple-choice questions after the article. Test behavior, sequence, tradeoffs, or failure cases from the explanation.

- Avoid naming trivia, hidden assumptions, and questions answerable without understanding the topic.
- Use plausible distractors. Balance specificity and vary option lengths so correct answers do not stand out.
- Use one labeled radio group per question, with unique identifiers and associated labels.
- After each selection, show whether the answer is correct and explain why.
- Link feedback to the relevant article section.
- Allow changed answers and update feedback without rebuilding the article or resetting demonstrations.
- Announce feedback through an accessible live region. Do not rely on color alone.
- Keep keyboard arrow selection within radio groups. Do not replace native controls with inaccessible click targets.
- Provide an answer key with explanations through a labeled disclosure, including when JavaScript is disabled.
- Keep answer text and feedback clear. Do not make humorous choices reveal the correct answer.

## Final checklist

Before delivery, verify:

- the complete HTML document exists at the requested path;
- the opening states a concrete problem and the main idea;
- the explanation follows a coherent worked example and preserves essential limitations;
- the voice is friendly and original, with permitted humor subordinate to technical clarity;
- source facts, assumptions, examples, and verification status remain distinct;
- visuals explain behavior rather than decorate the page;
- interactive demonstrations have correct states, accessible controls, and static alternatives;
- the light grey desktop layout uses approximately 70% article width and 30% right-side notes with one document scrollbar;
- the Grey palette matches the theme source, with `#f2f2f2` backgrounds and black text on `#f9db70` passage highlights;
- each desktop note's first text line aligns with its actual highlighted text line, not the top of the containing section;
- note positions update after layout changes without collisions, clipping, or accumulated offsets;
- mobile notes follow their related passages in normal flow;
- hover, focus, tap, and return links identify matching passages and notes without hiding content;
- the article, notes, demonstrations, and quiz remain readable without document overflow;
- `j`/`k` scroll by one text line and `Ctrl+d`/`Ctrl+u` scroll by half the current viewport;
- `gg` reaches the document top only after two separate presses; `G` reaches the current document bottom;
- the shortcut toggle, held keys, boundaries, and control exclusions work without changing focus or quiz answers;
- external requirements and failure states are explicit;
- all five quiz questions provide correct immediate feedback and relevant section links;
- the article and answer key remain readable without JavaScript;
- the delivery report states completed checks and any skipped verification.
