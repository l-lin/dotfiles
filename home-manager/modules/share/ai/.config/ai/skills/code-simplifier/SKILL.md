---
name: code-simplifier
description: Use when simplifying recently touched code without changing behavior, especially when asked to "simplify code", "clean up code", "refactor for clarity", or "improve readability".
disable-model-invocation: false
---

Simplify recent code. Preserve behavior. Follow project standards.

1. Find the code the user changed, or the code touched in this session. Ignore unrelated areas unless the user asks for a broader pass.
2. Read the repo guidance, especially `AGENTS.md` when present, and match existing project conventions.
3. Simplify for clarity:
   - remove dead helpers, duplication, and needless comments
   - reduce nesting and conditional sprawl
   - prefer explicit names and straightforward control flow
   - avoid clever one-liners and nested ternaries
4. Keep the smallest safe diff. Do not add abstractions, config, or helpers unless they make the touched code easier to understand right now.
5. Preserve behavior exactly. If intent or safety is unclear, stop and ask instead of guessing.
6. Verify the result against the changed code, then report only the simplifications that matter to understanding.
