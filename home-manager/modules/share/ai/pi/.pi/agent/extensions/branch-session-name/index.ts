import { existsSync } from "node:fs";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { buildSessionNameLine } from "./widget.js";

export default function branchSessionName(pi: ExtensionAPI) {
  function updateSessionWidget(ctx: ExtensionContext) {
    if (!ctx.hasUI) return;
    const name = ctx.sessionManager.getSessionName();
    if (!name?.trim()) {
      ctx.ui.setWidget("session-name", undefined);
      return;
    }

    ctx.ui.setWidget(
      "session-name",
      (_tui, theme) => ({
        render(width: number): string[] {
          const line = buildSessionNameLine(width, theme, name);
          return line ? [line] : [];
        },
        invalidate() {},
      }),
      { placement: "aboveEditor" },
    );
  }

  pi.on("session_info_changed", (_event, ctx) => {
    updateSessionWidget(ctx);
  });

  pi.on("session_start", async (event, ctx) => {
    updateSessionWidget(ctx);
    if (event.reason !== "startup" && event.reason !== "new") return;
    if (ctx.sessionManager.getSessionName()) return;

    // Startup also covers sessions loaded through CLI resume options.
    if (event.reason === "startup") {
      const file = ctx.sessionManager.getSessionFile();
      if (
        (file && existsSync(file)) ||
        ctx.sessionManager.getHeader()?.parentSession ||
        ctx.sessionManager
          .getEntries()
          .some((entry) => entry.type === "message")
      )
        return;
    }

    let result;
    try {
      result = await pi.exec("git", ["branch", "--show-current"], {
        cwd: ctx.cwd,
        timeout: 5000,
      });
    } catch {
      return;
    }

    if (result.code !== 0 || result.killed || result.truncated) return;
    const branch = result.stdout.trim();
    if (!branch || branch === "main" || branch === "master") return;
    if (ctx.sessionManager.getSessionName()) return;
    pi.setSessionName(branch);
  });
}
