/**
 * active-skills pi extension
 *
 * Watches for read tool calls that load a SKILL.md file and displays a widget
 * below the editor listing every skill activated in the current session.
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isReadToolResult } from "@mariozechner/pi-coding-agent";
import { SkillTracker, isSkillPath } from "./tracker.js";
import { updateSkillWidget, clearSkillWidget } from "./widget.js";

export default function (pi: ExtensionAPI) {
  const tracker = new SkillTracker();

  pi.on("session_start", (_event, _ctx) => {
    tracker.reset();
  });

  pi.on("session_shutdown", (_event, ctx) => {
    tracker.reset();
    clearSkillWidget(ctx);
  });

  // Intercept read tool calls *after* they complete so we only record skills
  // the agent actually read (not just attempted).
  pi.on("tool_result", async (event, ctx) => {
    if (!isReadToolResult(event)) return;

    const filePath = event.input.path as string | undefined;
    if (!filePath || !isSkillPath(filePath)) return;

    tracker.activate(filePath);
    updateSkillWidget(ctx, tracker.list());
  });
}
