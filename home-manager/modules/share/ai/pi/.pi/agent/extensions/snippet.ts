/**
 * Replace input containing snippets with pre-defined snippets.
 *
 * ?q  → "Use AskUserQuestion tool if there are any points to clarify."
 *
 * src: https://github.com/badlogic/pi-mono/blob/3a3e37d39014acc4269171be2a51518f6a71be1f/packages/coding-agent/examples/extensions/input-transform.ts
 * Adapted to use my own snippets
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("input", async (event, ctx) => {
    // Source-based logic: skip processing for extension-injected messages
    if (event.source === "extension") {
      return { action: "continue" };
    }

    // Transform: replace ?q with clarification instruction
    if (event.text.includes("?q")) {
      return {
        action: "transform",
        text: event.text.replace(/\?q/g, "Use ask-user-question tool if there are any points to clarify."),
      };
    }

    return { action: "continue" };
  });
}
