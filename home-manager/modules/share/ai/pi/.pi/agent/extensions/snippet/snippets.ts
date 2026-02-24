/**
 * Shared snippet definitions.
 *
 * Each entry declares:
 *  - trigger     — the short code the user types (e.g. "?q", "$date")
 *  - description — shown in the autocomplete popup
 *  - expansion   — the replacement text, or a thunk for dynamic values
 *
 * Consumed by:
 *  - snippet/index.ts        (input-transform extension)
 *  - custom-editor/snippets.ts (autocomplete provider)
 */

export interface SnippetDef {
  trigger: string;
  description: string;
  expansion: string | (() => string);
}

export const SNIPPETS: SnippetDef[] = [
  {
    trigger: "?q",
    description: "Ask for clarification points",
    expansion: "Use ask-user-question tool if there are any points to clarify.",
  },
  {
    trigger: "$date",
    description: "Insert today's date (YYYY-MM-DD)",
    expansion: () => new Date().toISOString().split("T")[0],
  },
  {
    trigger: "$tdd",
    description: "Use red/green TDD",
    expansion: "Use red/green TDD.",
  },
  {
    trigger: "$test_pi",
    description: "Test pi extension via tmux",
    expansion: "Test the pi extension with tmux by spawning a new pi session with 'pi --models \"github-copilot/gpt-4o\"",
  },
];
