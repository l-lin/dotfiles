import { existsSync } from "node:fs";
import {
  SessionManager,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { buildSessionNameLine } from "./widget.js";

export default function sessionName(pi: ExtensionAPI) {
  let pendingResume: { branch: string; sessionId: string } | undefined;
  let resumeImmediate: ReturnType<typeof setImmediate> | undefined;
  let active = true;

  pi.registerCommand("branch-session-auto-resume", {
    description: "Resume the branch session selected at startup",
    handler: async (_args, ctx) => {
      const pending = pendingResume;
      pendingResume = undefined;
      if (!pending || ctx.mode !== "tui") return;

      const canResume = () =>
        active &&
        ctx.sessionManager.getSessionId() === pending.sessionId &&
        ctx.sessionManager.getSessionName() === pending.branch &&
        !ctx.sessionManager
          .getEntries()
          .some((entry) => entry.type === "message");

      if (!canResume()) return;
      try {
        const sessions = await SessionManager.list(
          ctx.cwd,
          ctx.sessionManager.getSessionDir(),
        );
        if (!canResume()) return;
        const match = sessions.find(
          (session) =>
            session.name === pending.branch &&
            session.cwd === ctx.cwd &&
            session.path !== ctx.sessionManager.getSessionFile(),
        );
        if (!match) return;

        const result = await ctx.switchSession(match.path);
        if (!result.cancelled) return;
        ctx.ui.notify(
          "Automatic branch session resume was cancelled.",
          "warning",
        );
      } catch (error) {
        if (!active) return;
        const message = error instanceof Error ? error.message : String(error);
        ctx.ui.notify(
          `Cannot resume the branch session: ${message}`,
          "warning",
        );
      }
    },
  });

  pi.on("resources_discover", () => {
    if (!pendingResume || resumeImmediate) return;
    // Pi has no startup-complete event; slow resource discovery can overlap this command.
    resumeImmediate = setImmediate(() => {
      resumeImmediate = undefined;
      pi.sendUserMessage("/branch-session-auto-resume", {
        expandPromptTemplates: true,
      });
    });
  });

  pi.on("session_shutdown", () => {
    active = false;
    pendingResume = undefined;
    if (resumeImmediate) clearImmediate(resumeImmediate);
    resumeImmediate = undefined;
  });

  function updateSessionWidget(ctx: ExtensionContext) {
    if (!ctx.hasUI) return;
    ctx.ui.setWidget(
      "session-name",
      (_tui, theme) => ({
        render(width: number): string[] {
          const line = buildSessionNameLine(
            width,
            theme,
            ctx.sessionManager.getSessionName(),
          );
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

    if (!active || result.code !== 0 || result.killed || result.truncated)
      return;
    const branch = result.stdout.trim();
    if (!branch || branch === "main" || branch === "master") return;
    if (ctx.sessionManager.getSessionName()) return;
    pi.setSessionName(branch);

    if (
      event.reason === "startup" &&
      ctx.mode === "tui" &&
      ctx.sessionManager.getSessionFile() &&
      !process.argv
        .slice(2)
        .some((arg) =>
          [
            "--continue",
            "-c",
            "--resume",
            "-r",
            "--session",
            "--no-session",
          ].includes(arg),
        )
    ) {
      pendingResume = {
        branch,
        sessionId: ctx.sessionManager.getSessionId(),
      };
    }
  });
}
