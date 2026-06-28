/**
 * active-skills pi extension
 *
 * Watches for read tool calls that load a SKILL.md file and displays a widget
 * below the editor listing every skill activated in the current session.
 */
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { isReadToolResult } from "@earendil-works/pi-coding-agent";
import { SkillTracker, isSkillPath } from "./tracker.js";
import { updateSkillWidget, clearSkillWidget } from "./widget.js";

export default function (pi: ExtensionAPI) {
  const tracker = new SkillTracker();

  const rebuildWidgetFromBranch = (ctx: ExtensionContext) => {
    tracker.rebuildFromHistory(ctx);
    updateSkillWidget(ctx, tracker.list());
  };

  // Fresh sessions start empty.
  // Startup/reload/resume/fork should rebuild from the active branch so the
  // widget reflects skills that are still in scope.
  pi.on("session_start", (event, ctx) => {
    if (event.reason === "new") {
      tracker.reset();
      clearSkillWidget(ctx);
      return;
    }

    rebuildWidgetFromBranch(ctx);
  });

  // /tree keeps the same session file but changes the active branch, so
  // branch-scoped widget state must be reconstructed.
  pi.on("session_tree", (_event, ctx) => {
    rebuildWidgetFromBranch(ctx);
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
