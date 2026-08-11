---
name: explain-visually
description: Use when the user wants a visual explanation of code, systems, plans, or concepts, especially when ASCII, HTML, or Mermaid would explain it more clearly than plain prose.
disable-model-invocation: true
---

Explain the topic with visual cues.

1. Check whether the user explicitly chose `ASCII`, `HTML`, or `Mermaid`.
2. If not, default to `ASCII`.
3. Apply the matching reference:
   - `ASCII`: `./references/ASCII.md`
   - `HTML`: `./references/HTML.md`
   - `Mermaid`: `./references/MERMAID.md`
4. Do not ask which format to use unless the user explicitly wants an interactive choice.
