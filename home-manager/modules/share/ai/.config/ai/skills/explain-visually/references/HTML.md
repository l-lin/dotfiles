Generate self-contained HTML pages that explain systems, code changes, plans, data, and technical concepts visually. Use this skill for diagram requests, architecture overviews, diff/plan reviews, project recaps, comparison tables, slide decks, and any visual explanation.

## Delivery rules

- Prefer an HTML page over terminal ASCII when the output is inherently visual.
- If a table would have 4+ rows or 3+ columns, render it as HTML and give only a short chat summary.
- Write files to `.sandbox/diagrams/YYYY-MM-DD-description/` or the explicit eval output path. Use descriptive filenames.
- Open generated pages in the browser when running normally.
- The final page must be a complete self-contained HTML document, including embedded CSS and any needed JS.
- Include an in-page quiz with exactly five multiple-choice questions.
- Make the quiz medium difficulty: the reader should need to understand the substance of the explanation, not memorize trivia.
- Each question must give immediate feedback after selection: whether the answer was correct, why, and what detail in the explanation matters.

## Choose the representation

| Content | Default representation |
|---|---|
| Flowchart, pipeline, state machine, decision tree | Pele (Mermaid syntax) |
| Sequence, ER/schema, class, C4, topology-focused architecture | Pele (Mermaid syntax) |
| Text-heavy architecture, module internals, implementation plans | CSS grid cards, optionally with a Pele overview |
| 15+ element architecture | Hybrid: small Pele overview + CSS detail cards |
| Comparison/audit/status matrix | Semantic HTML `<table>` |
| Timeline/roadmap | CSS timeline |
| Dashboard/metrics | CSS grid + charts/KPIs |
| Slide deck | `100dvh` slides using slide template patterns |

## Pele diagram invariants

- Use [Pele](https://pele.run/) to render Mermaid syntax to inline SVG, not Mermaid.js. See the [API](https://pele.run/api), [theming](https://pele.run/theming), and [compatibility](https://pele.run/compatibility) references.
- Keep the page self-contained: embed the Pele browser bundle (`pele/global`) and diagram source in the HTML, or embed pre-rendered SVG with the needed interaction JS. Do not depend on a runtime CDN import.
- Bind Pele's CSS variables to the page palette and fonts on `.diagram-shell` so diagrams inherit the HTML theme. Color changes apply without re-rendering. Mermaid `theme` and `themeVariables` do not apply; Pele uses its own layout, not Mermaid's ELK configuration.
- Avoid fixed colors in diagram `style`, `classDef`, and `linkStyle` statements; they override the inherited theme.
- Never use bare `<pre class="mermaid">`. Mount into a block container inside `.diagram-shell` with `pele.mount(container, source, { zoom: true })`. For pre-rendered SVG, attach `pele.enableZoom(container, { always: true })`.
- Every diagram needs zoom in/out/reset/expand controls, Ctrl/Cmd+scroll zoom, drag panning, and click-to-expand. Pele provides zoom controls and panning; add expand controls and click-to-expand separately. Call the mounted diagram's `refresh()` after moving it into an expanded view.
- Prefer `flowchart TD` for complex diagrams. Use `LR` only for simple 3–4 node linear flows.
- Use `<br/>` in quoted flowchart labels. Do not use escaped `\n` labels. Pele supports line breaks, bold, and italic, not arbitrary HTML labels.
- Use namespaced page classes such as `.ve-card`; target diagram elements with Pele's `.pele-*` classes.
- For 15+ elements, do not cram everything into one diagram. Use the hybrid overview + cards pattern.

Map these variables to the page's existing tokens, using its accent and font token names in place of the example names:

```css
.diagram-shell {
  --pele-bg: var(--bg);
  --pele-fg: var(--text);
  --pele-muted: var(--text-dim);
  --pele-line: var(--text-dim);
  --pele-surface: var(--surface);
  --pele-surface-alt: var(--bg);
  --pele-border: var(--border);
  --pele-accent: var(--accent);
  --pele-critical: var(--accent);
  --pele-error: var(--accent);
  --pele-font: var(--font-body);
  --pele-font-mono: var(--font-mono);
}
```

For charts and color-coded categories, map `--pele-series-1` through `--pele-series-8` to the page's accents, reusing colors as needed. Check text contrast against `--pele-bg`. Define the font tokens before mounting; `mount()` reads them from CSS and redraws after pending web fonts load. Call `refresh()` after changing fonts. When pre-rendering with `render()`, pass matching `fontFamily` and `fontFamilyMono` options so label measurements match the page.

## Layout and style invariants

- ALWAYS use light background.
- Use semantic HTML where it helps accessibility and copy/paste: `<table>`, headings, lists, `<details>`, captions.
- Use CSS custom properties for palette: `--bg`, `--surface`, `--border`, `--text`, `--text-dim`, and 3–5 accents.
- Pick a clear aesthetic direction before writing: blueprint, editorial, paper/ink, terminal, IDE-inspired, or data-dense.
- ALWAYS use minimalist style that highlights readability over nice looking HTML page.
  - Prefer using 5 colors max.
- Prevent overflow: `min-width: 0` on grid/flex children, `overflow-wrap: break-word` for long text, and scroll containers for wide tables/code.
- Do not set `display: flex` directly on `<li>` when list markers matter.
- Use depth sparingly: hero/elevated only for primary sections; flat/recessed for reference material.
- Use entrance/hover animation only when it clarifies hierarchy. Respect `prefers-reduced-motion`. Do not use continuous glow, pulse, or breathing effects on static content.

## Slide deck mode

Use slides only when explicitly requested or when a command asks for slides. Slides are a different medium, not a paginated article:

- Each slide is one viewport (`100dvh`) with no page-level scrolling.
- Use larger type, fewer objects per slide, varied compositions, and visible navigation.
- Include slide nav chrome: prev/next controls, slide count, keyboard navigation, and carousel dots/indicators.
- Before writing HTML, inventory the source and map every source item to slides.
- Do not drop content to fit a fixed slide count. Add slides instead.

## Quiz requirements

Build the quiz into the HTML page itself.

- Use exactly five multiple-choice questions.
- Test the explanation's key ideas, behavior, tradeoffs, risks, implementation shape, or sequence, depending on the topic.
- Avoid gotchas, naming trivia, and details the reader could answer without understanding the material.
- Do not make the correct answer easy to spot by length, detail, or tone. Vary option lengths across all choices, and make distractors plausible.
- When one option needs extra specificity, balance the set by giving similar specificity to at least one distractor.
- Make the interaction obvious and lightweight: radio buttons or buttons are fine.
- After a choice, show whether it was correct and give short feedback tied to the explanation.

## Final checklist

Before delivery, verify:

- complete HTML document;
- output written to the requested path;
- no console errors when opened;
- no horizontal overflow at normal desktop width;
- fonts load with fallbacks;
- tables preserve rows/columns and wrap long text;
- Mermaid syntax is rendered by Pele as inline SVG, with palette and fonts inherited from the page through `--pele-*` variables;
- diagrams use `diagram-shell` with zoom/pan/expand and no runtime CDN dependency;
- slides fit one viewport, include carousel dots, and preserve source coverage;
- pages include a five-question interactive multiple-choice quiz with answer feedback;
- correct quiz answers are not systematically longer or more detailed than distractors;
- visual hierarchy makes the main idea obvious in the first viewport;
