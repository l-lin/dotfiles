/**
 * Snippet autocomplete provider.
 *
 * Trigger/description data lives in snippet/snippets.ts — shared with the
 * input-transform extension so both stay in sync automatically.
 */

import type { AutocompleteItem, AutocompleteProvider } from "@mariozechner/pi-tui";
import { SNIPPETS } from "../snippet/snippets.js";

type RuntimeAutocompleteOptions = {
  signal?: AbortSignal;
  force?: boolean;
};

export class SnippetAutocompleteProvider {
  getSuggestions(
    lines: string[],
    cursorLine: number,
    cursorCol: number,
  ): { items: AutocompleteItem[]; prefix: string } | null {
    const text  = (lines[cursorLine] ?? "").slice(0, cursorCol);
    const match = text.match(/([$?][a-zA-Z0-9_]*)$/);
    if (!match) return null;

    const prefix = match[1]!;
    const items  = SNIPPETS
      .filter((s) => s.trigger.startsWith(prefix))
      .map((s) => ({ value: s.trigger, label: s.trigger, description: s.description }));

    return items.length > 0 ? { items, prefix } : null;
  }
}

/**
 * Wrap an existing AutocompleteProvider to prepend snippet suggestions.
 * Snippet items use direct text replacement; all other items delegate to base.
 */
export function withSnippets(base: AutocompleteProvider): AutocompleteProvider {
  const snippets = new SnippetAutocompleteProvider();
  const runtimeBase = base as AutocompleteProvider & {
    getSuggestions(
      lines: string[],
      cursorLine: number,
      cursorCol: number,
      options?: RuntimeAutocompleteOptions,
    ): ReturnType<AutocompleteProvider["getSuggestions"]>;
  };

  return {
    getSuggestions: (lines, cursorLine, cursorCol, options?: RuntimeAutocompleteOptions) =>
      snippets.getSuggestions(lines, cursorLine, cursorCol) ??
      runtimeBase.getSuggestions(lines, cursorLine, cursorCol, options),

    applyCompletion: (lines, cursorLine, cursorCol, item, prefix) => {
      // Snippet items use a simple prefix replacement — don't delegate to base,
      // which has slash-command-specific formatting (trailing spaces, etc.)
      if (/^[$?]/.test(prefix)) {
        const line     = lines[cursorLine] ?? "";
        const newLines = [...lines];
        newLines[cursorLine] =
          line.slice(0, cursorCol - prefix.length) + item.value + line.slice(cursorCol);
        return {
          lines: newLines,
          cursorLine,
          cursorCol: cursorCol - prefix.length + item.value.length,
        };
      }
      return base.applyCompletion(lines, cursorLine, cursorCol, item, prefix);
    },
  };
}
