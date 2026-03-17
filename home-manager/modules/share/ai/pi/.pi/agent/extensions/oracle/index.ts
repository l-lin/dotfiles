/**
 * Oracle Extension - Get a second opinion from another AI model
 *
 * Usage:
 *   /oracle <prompt>              - Opens model picker, then queries
 *   /oracle -m gpt-4o <prompt>    - Direct to specific model
 *   /oracle -f file.ts <prompt>   - Include file(s) in context
 *
 * src: https://github.com/hjanuschka/shitty-extensions/blob/0898c8ce4bf4d598863e0d9a979485d533445f15/extensions/oracle.ts
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { executeOracle, showModelPicker } from "./execute.js";
import { type AvailableModel, ORACLE_MODELS } from "./types.js";

async function resolveAvailableModels(
  ctx: ExtensionContext,
): Promise<AvailableModel[]> {
  const available: AvailableModel[] = [];

  for (const m of ORACLE_MODELS) {
    const model = ctx.modelRegistry.find(m.provider, m.model);
    if (!model) continue;
    if (ctx.model && model.id === ctx.model.id) continue;

    const apiKey = await ctx.modelRegistry.getApiKey(model);
    if (!apiKey) continue;

    available.push({
      provider: m.provider,
      modelId: m.model,
      name: m.name,
      model,
      apiKey,
    });
  }
  return available;
}

function parseArgs(
  args: string,
): { modelArg?: string; files: string[]; prompt: string } | null {
  const tokens = args.trim().split(/\s+/);
  let modelArg: string | undefined;
  const files: string[] = [];
  let i = 0;

  while (i < tokens.length) {
    const token = tokens[i];
    if (token === "-m" || token === "--model") {
      if (++i >= tokens.length) return null;
      modelArg = tokens[i];
    } else if (token === "-f" || token === "--file") {
      if (++i >= tokens.length) return null;
      files.push(tokens[i]);
    } else {
      return { modelArg, files, prompt: tokens.slice(i).join(" ") };
    }
    i++;
  }
  return null;
}

function findModel(
  models: AvailableModel[],
  query: string,
): AvailableModel | undefined {
  return models.find(
    (m) =>
      m.modelId === query ||
      m.modelId.includes(query) ||
      m.name.toLowerCase().includes(query.toLowerCase()),
  );
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("cmd:oracle", {
    description: "Get a second opinion from another AI model",
    handler: async (args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify("oracle requires interactive mode", "error");
        return;
      }
      if (!args?.trim()) {
        ctx.ui.notify(
          "Usage: /oracle <prompt> or /oracle -f file.ts <prompt>",
          "error",
        );
        return;
      }

      const parsed = parseArgs(args);
      if (!parsed?.prompt) {
        ctx.ui.notify("No prompt provided", "error");
        return;
      }

      const availableModels = await resolveAvailableModels(ctx);
      if (availableModels.length === 0) {
        ctx.ui.notify(
          "No alternative models available. Check API keys.",
          "error",
        );
        return;
      }

      const { modelArg, files, prompt } = parsed;

      // Direct model selection via -m flag
      if (modelArg) {
        const found = findModel(availableModels, modelArg);
        if (!found) {
          ctx.ui.notify(`Model "${modelArg}" not available`, "error");
          return;
        }
        await executeOracle(pi, ctx, prompt, files, found);
        return;
      }

      // Interactive model picker
      const selected = await showModelPicker(
        ctx,
        availableModels,
        prompt,
        files,
      );
      if (!selected) {
        ctx.ui.notify("Cancelled", "info");
        return;
      }
      await executeOracle(pi, ctx, prompt, files, selected);
    },
  });

  pi.registerMessageRenderer("oracle-response", (message, options, theme) => {
    const details =
      (message.details as { modelName?: string; files?: string[] }) || {};
    let text = theme.fg(
      "accent",
      `🔮 Oracle (${details.modelName || "unknown"}):\n\n`,
    );
    text += message.content;

    if (options.expanded && details.files && details.files.length > 0) {
      text += "\n\n" + theme.fg("dim", `Files: ${details.files.join(", ")}`);
    }
    return new Text(text, 0, 0);
  });
}
