---
name: explain-visually
description: Use for visual explanations of code, systems, plans, or concepts through ASCII, HTML, Mermaid, zines, blog tutorials, or pull request articles.
disable-model-invocation: true
---

Explain the topic with visual cues.

1. Check whether the user explicitly chose `ascii`, `html`, `zine`, `blog`, or `pr-blog` (case-insensitive).
2. If not, default to `ASCII`.
3. Apply the matching reference:
   - `ascii`: `./references/ASCII.md`
   - `html`: `./references/HTML.md`
   - `zine`: `./references/ZINE.md`
   - `blog`: `./references/BLOG.md`
   - `pr-blog`: `./references/PR-BLOG.md`
4. Do not ask which format to use unless the user explicitly wants an interactive choice.
