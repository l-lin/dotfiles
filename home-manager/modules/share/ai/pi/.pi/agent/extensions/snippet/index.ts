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
import { SNIPPETS } from "./snippets.js";

/** Escape special regex characters in a literal string. */
function escapeRegex(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

export default function (pi: ExtensionAPI) {
  pi.on("input", async (event, _ctx) => {
    // Skip extension-injected messages to avoid infinite loops.
    if (event.source === "extension") {
      return { action: "continue" };
    }

    for (const snippet of SNIPPETS) {
      if (event.text.includes(snippet.trigger)) {
        const value =
          typeof snippet.expansion === "function"
            ? snippet.expansion()
            : snippet.expansion;
        return {
          action: "transform",
          text: event.text.replace(new RegExp(escapeRegex(snippet.trigger), "g"), value),
        };
      }
    }

    return { action: "continue" };
  });
}
