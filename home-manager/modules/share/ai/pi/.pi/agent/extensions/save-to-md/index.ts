/**
 * Pi extension that saves the latest assistant response on the active session branch as Markdown.
 *
 * Usage:
 * - /cmd:save-to-md name
 *
 * src: https://github.com/dmmulroy/.dotfiles/blob/a8bb98e2f5ada7639442b51d3dc4580cb62b7b24/home/.pi/agent/extensions/save-md/index.ts
 */

import { mkdir, writeFile } from "node:fs/promises";
import { resolve } from "node:path";

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function textContent(content: unknown): string {
  if (!Array.isArray(content)) return "";

  return content
    .filter(
      (block): block is { type: "text"; text: string } =>
        typeof block === "object" &&
        block !== null &&
        "type" in block &&
        block.type === "text" &&
        "text" in block &&
        typeof block.text === "string",
    )
    .map((block) => block.text)
    .join("\n\n");
}

function formatDefaultFileName(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  const hours = String(date.getHours()).padStart(2, "0");
  const minutes = String(date.getMinutes()).padStart(2, "0");
  const seconds = String(date.getSeconds()).padStart(2, "0");

  return `${year}-${month}-${day}-${hours}${minutes}${seconds}.md`;
}

export default function saveMarkdownExtension(pi: ExtensionAPI) {
  pi.registerCommand("cmd:save-to-md", {
    description:
      "Save the latest assistant response as Markdown in .sandbox/responses (usage: /cmd:save-to-md [name])",
    handler: async (args, ctx) => {
      await ctx.waitForIdle();

      const branch = ctx.sessionManager.getBranch();
      let assistantMessage: AssistantMessage | undefined;
      for (let index = branch.length - 1; index >= 0; index--) {
        const entry = branch[index];
        if (entry?.type === "message" && entry.message.role === "assistant") {
          assistantMessage = entry.message;
          break;
        }
      }
      if (!assistantMessage) {
        ctx.ui.notify("No assistant response to save", "warning");
        return;
      }

      const markdown = textContent(assistantMessage.content);
      if (!markdown.trim()) {
        ctx.ui.notify(
          "The latest assistant response has no Markdown text",
          "warning",
        );
        return;
      }

      const name = args.trim();
      const fileName = name
        ? name.endsWith(".md")
          ? name
          : `${name}.md`
        : formatDefaultFileName(new Date());
      const directory = resolve(ctx.cwd, ".sandbox", "responses");
      const path = resolve(directory, fileName);

      try {
        await mkdir(directory, { recursive: true });
        await writeFile(
          path,
          markdown.endsWith("\n") ? markdown : `${markdown}\n`,
          {
            encoding: "utf8",
            flag: "wx",
          },
        );
      } catch (error) {
        if (
          typeof error === "object" &&
          error !== null &&
          "code" in error &&
          error.code === "EEXIST"
        ) {
          ctx.ui.notify(`File already exists: ${path}`, "error");
          return;
        }
        throw error;
      }

      const message = `Saved Markdown to ${path}`;
      pi.sendMessage(
        {
          customType: "save-to-md",
          content: message,
          display: true,
        },
        { deliverAs: "nextTurn" },
      );
      ctx.ui.notify(message, "info");
    },
  });
}
