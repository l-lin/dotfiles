/**
 * Enforce Modern CLI Tools Extension
 *
 * Hard-blocks bash commands that use legacy tools when modern equivalents are available:
 * - `grep` → use `rg`
 * - `find` → use `fd`
 *
 * The block returns a descriptive error so the LLM understands what to use instead.
 * Note: regexes intentionally omit the `g` flag to avoid stateful `lastIndex` issues.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
  ToolCallEvent,
} from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

interface BlockedTool {
  /** Regex that matches the forbidden usage in a bash command */
  pattern: RegExp;
  /** Legacy tool name, for human-readable messages */
  legacy: string;
  /** Replacement to suggest */
  replacement: string;
}

const BLOCKED_TOOLS: BlockedTool[] = [
  {
    // Match `grep` but not `egrep`, `fgrep`, `zgrep` (negative lookbehind on preceding letter) or `grepfile`.
    pattern: /(?<![a-z])grep(?!file)\b/,
    legacy: "grep",
    replacement: "rg",
  },
  {
    // Match `find` as a standalone command (not `findstr`, `finder`, `find-files`, etc.)
    pattern: /(?<![a-z\-_])find(?![\w\-])/,
    legacy: "find",
    replacement: "fd",
  },
];

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event: ToolCallEvent, ctx: ExtensionContext) => {
    if (!isToolCallEventType("bash", event)) return undefined;

    const command = event.input.command;

    for (const { pattern, legacy, replacement } of BLOCKED_TOOLS) {
      if (pattern.test(command)) {
        const reason = `Use \`${replacement}\` instead of \`${legacy}\``;

        if (ctx.hasUI) ctx.ui.notify(reason, "warning");

        return { block: true, reason };
      }
    }

    return undefined;
  });
}
