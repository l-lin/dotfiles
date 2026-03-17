/**
 * Replace input containing snippet triggers with their expansions.
 *
 * Snippet definitions live in ./snippets.ts so they can be shared with the
 * custom-editor autocomplete provider.
 *
 * src: https://github.com/badlogic/pi-mono/blob/3a3e37d39014acc4269171be2a51518f6a71be1f/packages/coding-agent/examples/extensions/input-transform.ts
 * Adapted to use my own snippets
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { SNIPPETS, type SnippetDef } from "./snippets.js";

function escapeRegex(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function resolveExpansion(snippet: SnippetDef): string {
  return typeof snippet.expansion === "function"
    ? snippet.expansion()
    : snippet.expansion;
}

export default function (pi: ExtensionAPI) {
  pi.on("input", async (event, _ctx) => {
    if (event.source === "extension") {
      return { action: "continue" };
    }

    const original = event.text;
    let text = original;

    for (const snippet of SNIPPETS) {
      if (text.includes(snippet.trigger)) {
        text = text.replace(
          new RegExp(escapeRegex(snippet.trigger), "g"),
          resolveExpansion(snippet),
        );
      }
    }

    return text !== original
      ? { action: "transform", text }
      : { action: "continue" };
  });
}
