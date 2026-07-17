/**
 * Snippet autocomplete provider.
 *
 * Trigger/description data lives in snippet/snippets.ts so Ctrl-E expansion,
 * autocomplete, and the compatibility shim share one catalog.
 */

import type {
  AutocompleteItem,
  AutocompleteProvider,
} from "@earendil-works/pi-tui";
import { SNIPPETS, type SnippetDef } from "../snippet/snippets.js";

type RuntimeAutocompleteOptions = {
  signal: AbortSignal;
  force?: boolean;
};

type ScoredSnippetMatch = {
  score: number;
  snippet: SnippetDef;
  index: number;
};

function toAutocompleteItem(snippet: SnippetDef): AutocompleteItem {
  return {
    value: snippet.trigger,
    label: snippet.trigger,
    description: snippet.description,
  };
}

function fuzzyScoreTrigger(query: string, trigger: string): number {
  const normalizedQuery = query.trim().toLowerCase();
  const normalizedTrigger = trigger.toLowerCase();
  if (!normalizedQuery) return -1;

  const directIndex = normalizedTrigger.indexOf(normalizedQuery);
  if (directIndex !== -1) {
    return 10_000 - directIndex - normalizedTrigger.length;
  }

  let lastIndex = -1;
  let score = 0;
  for (const character of normalizedQuery) {
    const nextIndex = normalizedTrigger.indexOf(character, lastIndex + 1);
    if (nextIndex === -1) return -1;

    score += 8;
    if (nextIndex === lastIndex + 1) score += 6;
    if (
      nextIndex === 0 ||
      " /_-:(".includes(normalizedTrigger[nextIndex - 1] ?? "")
    ) {
      score += 4;
    }
    score -= Math.max(0, nextIndex - lastIndex - 1);
    lastIndex = nextIndex;
  }

  return score - normalizedTrigger.length;
}

function getPrefixMatches(prefix: string): AutocompleteItem[] {
  return SNIPPETS.filter((snippet) => snippet.trigger.startsWith(prefix)).map(
    toAutocompleteItem,
  );
}

function getFuzzyDollarMatches(prefix: string): AutocompleteItem[] {
  if (!prefix.startsWith("$") || prefix.length < 3) {
    return [];
  }

  const seenTriggers = new Set(
    getPrefixMatches(prefix).map((item) => item.value),
  );

  return SNIPPETS.map((snippet, index): ScoredSnippetMatch | null => {
    if (!snippet.trigger.startsWith("$") || seenTriggers.has(snippet.trigger)) {
      return null;
    }

    const score = fuzzyScoreTrigger(prefix, snippet.trigger);
    if (score < 0) {
      return null;
    }

    return { score, snippet, index };
  })
    .filter((match): match is ScoredSnippetMatch => match !== null)
    .sort((left, right) => {
      if (right.score !== left.score) {
        return right.score - left.score;
      }

      return left.index - right.index;
    })
    .map((match) => toAutocompleteItem(match.snippet));
}

export class SnippetAutocompleteProvider {
  getSuggestions(
    lines: string[],
    cursorLine: number,
    cursorCol: number,
  ): { items: AutocompleteItem[]; prefix: string } | null {
    const text = (lines[cursorLine] ?? "").slice(0, cursorCol);
    const match = text.match(/([$?][a-zA-Z0-9_-]*)$/);
    if (!match) return null;

    const prefix = match[1]!;
    const prefixMatches = getPrefixMatches(prefix);
    const fuzzyDollarMatches = getFuzzyDollarMatches(prefix);
    const items = [...prefixMatches, ...fuzzyDollarMatches];

    return items.length > 0 ? { items, prefix } : null;
  }
}

/**
 * Wrap an existing AutocompleteProvider to prepend snippet suggestions.
 * Snippet items use direct text replacement; all other items delegate to base.
 */
export function withSnippets(base: AutocompleteProvider): AutocompleteProvider {
  const snippets = new SnippetAutocompleteProvider();
  const triggerCharacters = Array.from(
    new Set([...(base.triggerCharacters ?? []), "$", "?"]),
  );

  return {
    triggerCharacters,
    shouldTriggerFileCompletion: base.shouldTriggerFileCompletion?.bind(base),
    async getSuggestions(
      lines,
      cursorLine,
      cursorCol,
      options: RuntimeAutocompleteOptions,
    ) {
      return (
        snippets.getSuggestions(lines, cursorLine, cursorCol) ??
        base.getSuggestions(lines, cursorLine, cursorCol, options)
      );
    },

    applyCompletion: (lines, cursorLine, cursorCol, item, prefix) => {
      // Snippet items use a simple prefix replacement — don't delegate to base,
      // which has slash-command-specific formatting (trailing spaces, etc.)
      if (/^[$?]/.test(prefix)) {
        const line = lines[cursorLine] ?? "";
        const newLines = [...lines];
        newLines[cursorLine] =
          line.slice(0, cursorCol - prefix.length) +
          item.value +
          line.slice(cursorCol);
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
