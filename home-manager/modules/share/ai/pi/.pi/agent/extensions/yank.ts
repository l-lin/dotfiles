/**
 * /yank
 *
 * Copies the latest agent (assistant) text output to the system clipboard.
 * Listens for message_end events and caches the last assistant message text.
 * Call /yank to push it to pbcopy.
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { spawn } from "node:child_process";

function extractTextFromMessage(message: unknown): string | undefined {
  if (!message || typeof message !== "object") return undefined;
  const m = message as Record<string, unknown>;
  if (m.role !== "assistant") return undefined;
  if (!Array.isArray(m.content)) return undefined;

  const parts: string[] = [];
  for (const block of m.content) {
    if (!block || typeof block !== "object") continue;
    const b = block as Record<string, unknown>;
    if (b.type === "text" && typeof b.text === "string" && b.text.trim()) {
      parts.push(b.text);
    }
  }

  return parts.length > 0 ? parts.join("\n\n") : undefined;
}

async function copyToClipboard(text: string): Promise<void> {
  return new Promise((resolve, reject) => {
    // TODO: Support smarter yank by checking which is enabled.
    const proc = spawn("pbcopy", [], { stdio: ["pipe", "ignore", "ignore"] });

    if (!proc.stdin) {
      reject(new Error("pbcopy: stdin unavailable"));
      return;
    }

    let settled = false;
    const settle = (fn: () => void) => {
      if (!settled) {
        settled = true;
        fn();
      }
    };

    // Suppress stdin errors — process-level errors are handled via proc.on("error")
    proc.stdin.on("error", () => {});
    proc.stdin.write(text, "utf8");
    proc.stdin.end();
    proc.on("close", (code) => {
      if (code === 0) settle(resolve);
      else settle(() => reject(new Error(`pbcopy exited with code ${code}`)));
    });
    proc.on("error", (err) => settle(() => reject(err)));
  });
}

export default function yankExtension(pi: ExtensionAPI) {
  let lastAssistantText: string | undefined;

  pi.on("message_end", (event) => {
    const text = extractTextFromMessage(event.message);
    if (text) {
      lastAssistantText = text;
    }
  });

  pi.registerCommand("yank", {
    description: "Copy the latest agent output to the system clipboard",
    handler: async (_args, ctx) => {
      if (!lastAssistantText) {
        ctx.ui.notify("󱘛 Nothing to yank", "warning");
        return;
      }

      try {
        await copyToClipboard(lastAssistantText);
        const preview =
          lastAssistantText.length > 50
            ? lastAssistantText.slice(0, 50).replace(/\n/g, " ") + "…"
            : lastAssistantText.replace(/\n/g, " ");
        ctx.ui.notify(`󰢨 ${preview}`, "info");
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : String(err);
        ctx.ui.notify(`󱘛 Failed to copy: ${msg}`, "error");
      }
    },
  });
}
