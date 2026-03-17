/**
 * Ask-User-Question Tool — single or multi-question option selection with TUI.
 *
 * src: https://github.com/badlogic/pi-mono/blob/81b8f9c083db63ed9b7ffb1f555fc6fee8653767/packages/coding-agent/examples/extensions/questionnaire.ts
 * Adapted with the following changes:
 * - rename extension to `ask-user-question` to match the same name as claude-code & opencode
 * - use keymaps from keybindings.json instead of hard coded keymaps (arrows, Esc, Enter)
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { loadSettings, saveEnabled } from "./settings.js";
import { error, QuestionnaireParams } from "./types.js";
import type { Question, Result } from "./types.js";
import { renderCall, renderResult } from "./render.js";
import { buildWidget } from "./widget.js";

export default function (pi: ExtensionAPI) {
  const settings = loadSettings();

  pi.registerCommand("cmd:ask-user-question-toggle", {
    description: "Toggle ask-user-question tool on/off",
    handler: async (_args, ctx) => {
      settings.enabled = !settings.enabled;
      saveEnabled(settings.enabled);
      if (settings.enabled) {
        pi.setActiveTools([
          ...new Set([...pi.getActiveTools(), "ask-user-question"]),
        ]);
      } else {
        pi.setActiveTools(
          pi.getActiveTools().filter((t) => t !== "ask-user-question"),
        );
      }
      ctx.ui.notify(
        `ask-user-question ${settings.enabled ? "enabled" : "disabled"}`,
        "info",
      );
      pi.events.emit("custom-tool:changed", {
        tool: "ask-user-question",
        enabled: settings.enabled,
      });
    },
  });

  if (!settings.enabled) return;

  pi.registerTool({
    name: "ask-user-question",
    label: "Ask user question",
    description:
      "Ask the user one or more questions. Single question shows options list; multiple questions show tab-based interface.",
    parameters: QuestionnaireParams,

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      if (!ctx.hasUI) return error("UI not available");
      if (!params.questions.length) return error("No questions provided");

      const questions: Question[] = params.questions.map((q, i) => ({
        ...q,
        label: q.label ?? `Q${i + 1}`,
      }));

      const result = await ctx.ui.custom<Result>(buildWidget(questions));

      if (result.cancelled) {
        return {
          content: [{ type: "text", text: "User cancelled" }],
          details: result,
        };
      }

      const text = result.answers
        .map((a) => {
          const label = questions.find((q) => q.id === a.id)?.label ?? a.id;
          return a.wasCustom
            ? `${label}: user wrote: ${a.label}`
            : `${label}: user selected: ${a.index != null ? `${a.index}. ` : ""}${a.label}`;
        })
        .join("\n");

      return { content: [{ type: "text", text }], details: result };
    },

    renderCall,
    renderResult,
  });
}
