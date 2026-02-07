---
name: yank
description: Improve or rewrite user-provided text (messages, emails, docs, UI copy) for clarity and tone, then copy (yank) the final improved version to the system clipboard. Use when user asks to improve/rewrite/polish/edit text, message, or email, especially if they mention copy/yank/clipboard.
---

# Yank (rewrite + copy to clipboard)

## Goal

Yank the final version to the clipboard.

## Workflow

1. If needed, ask for the text + any constraints (audience, tone, length).
2. Produce the improved text.
3. Yank the improved text to clipboard by using `copy`

```bash
cat <<'EOF' | copy
<FINAL_TEXT>
EOF
```

## Output rule

Show only the improved text as a clean block (no recap).
