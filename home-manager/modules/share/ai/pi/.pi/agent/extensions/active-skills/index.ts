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

  // New session: clear state and widget.
  // Resumed session: rebuild tracker from existing history so the widget
  // reflects skills that were already read in previous turns.
  pi.on("session_switch", (event, ctx) => {
    if (event.reason === "new") {
      tracker.reset();
      clearSkillWidget(ctx);
    } else {
      tracker.rebuildFromHistory(ctx);
      updateSkillWidget(ctx, tracker.list());
    }
  });

  // After /reload the extension is re-instantiated; restore widget from history.
  pi.on("resources_discover", (_event, ctx) => {
    tracker.rebuildFromHistory(ctx);
    updateSkillWidget(ctx, tracker.list());
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
