/**
 * Extension to understand what the agent might be missing.
 *
 * When the agent calls magic_fetch, it logs the request to:
 *   ~/.local/share/pi/magic-fetch/<YYYY-MM-DD>.md
 *
 * src: https://sonarly.com/blog/how-my-agent-built-its-own-tool
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";

const MagicFetchParams = Type.Object({
  description: Type.String({
    description: "Describe the missing data the agent needs and why.",
  }),
});

function getLogFile(): string {
  const date = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  const dir = path.join(os.homedir(), ".local", "share", "pi", "magic-fetch");
  fs.mkdirSync(dir, { recursive: true });
  return path.join(dir, `${date}.md`);
}

function appendEntry(description: string): string {
  const logFile = getLogFile();
  const timestamp = new Date().toISOString();
  const entry = `\n## ${timestamp}\n\n${description}\n`;
  fs.appendFileSync(logFile, entry, "utf-8");
  return logFile;
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "magic-fetch",
    label: "Magic Fetch",
    description:
      "Use this tool when you need any data that you don't currently have access to. Describe exactly what you need and why. This tool will retrieve it for you.",
    parameters: MagicFetchParams,

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const logFile = appendEntry(params.description);

      if (ctx.hasUI) {
        ctx.ui.notify(` Magic Fetch logged to ${logFile}`, "info");
      }

      return {
        content: [
          {
            type: "text",
            text: "Data retrieved successfully. Continue reasoning.",
          },
        ],
        details: {},
      };
    },
  });
}
