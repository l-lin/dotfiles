/**
 * /session-breakdown
 *
 * Interactive TUI that analyzes ~/.pi/agent/sessions (recursively, *.jsonl) and shows
 * last 7/30/90 days of:
 * - sessions/day
 * - messages/day
 * - tokens/day (if available)
 * - cost/day (if available)
 * - model breakdown (sessions/messages/tokens + cost)
 *
 * Graph:
 * - GitHub-contributions-style calendar (weeks x weekdays)
 * - Hue: weighted mix of popular model colors (weighted by the selected metric)
 * - Brightness: selected metric per day (log-scaled)
 *
 * src: https://github.com/mitsuhiko/agent-stuff/blob/6a304cfe34996bf9ffbadf0f849bb4f6f1cb5074/pi-extensions/session-breakdown.ts
 * Adapted to have light variant.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import { BorderedLoader } from "@mariozechner/pi-coding-agent";
import type { BreakdownData, BreakdownProgressState } from "./types.js";
import { formatCount } from "./color-utils.js";
import { computeBreakdown } from "./aggregation.js";
import { rangeSummary } from "./renderer.js";
import { BreakdownComponent } from "./component.js";

/** BorderedLoader wraps an inner Loader that supports setMessage() but doesn't expose it publicly. */
function setBorderedLoaderMessage(loader: BorderedLoader, message: string) {
  const inner = (loader as any)["loader"]; // eslint-disable-line @typescript-eslint/no-explicit-any
  if (inner && typeof inner.setMessage === "function") {
    inner.setMessage(message);
  }
}

export default function sessionBreakdownExtension(pi: ExtensionAPI) {
  pi.registerCommand("cmd:session-breakdown", {
    description:
      "Interactive breakdown of last 7/30/90 days of ~/.pi session usage (sessions/messages/tokens + cost by model)",
    handler: async (_args, ctx: ExtensionContext) => {
      if (!ctx.hasUI) {
        // Non-interactive fallback: just notify.
        const data = await computeBreakdown(undefined);
        const range = data.ranges.get(30)!;
        pi.sendMessage(
          {
            customType: "session-breakdown",
            content: `Session breakdown (non-interactive)\n${rangeSummary(range, 30, "sessions")}`,
            display: true,
          },
          { triggerTurn: false },
        );
        return;
      }

      let aborted = false;
      const data = await ctx.ui.custom<BreakdownData | null>(
        (tui, theme, _kb, done) => {
          const baseMessage = "Analyzing sessions (last 90 days)…";
          const loader = new BorderedLoader(tui, theme, baseMessage);

          const startedAt = Date.now();
          const progress: BreakdownProgressState = {
            phase: "scan",
            foundFiles: 0,
            parsedFiles: 0,
            totalFiles: 0,
            currentFile: undefined,
          };

          const renderMessage = (): string => {
            const elapsed = ((Date.now() - startedAt) / 1000).toFixed(1);
            if (progress.phase === "scan") {
              return `${baseMessage}  scanning (${formatCount(progress.foundFiles)} files) · ${elapsed}s`;
            }
            if (progress.phase === "parse") {
              return `${baseMessage}  parsing (${formatCount(progress.parsedFiles)}/${formatCount(progress.totalFiles)}) · ${elapsed}s`;
            }
            return `${baseMessage}  finalizing · ${elapsed}s`;
          };

          let intervalId: NodeJS.Timeout | null = null;
          const stopTicker = () => {
            if (intervalId) {
              clearInterval(intervalId);
              intervalId = null;
            }
          };

          // Update every 0.5s so long-running scans show some visible progress.
          setBorderedLoaderMessage(loader, renderMessage());
          intervalId = setInterval(() => {
            setBorderedLoaderMessage(loader, renderMessage());
          }, 500);

          loader.onAbort = () => {
            aborted = true;
            stopTicker();
            done(null);
          };

          computeBreakdown(loader.signal, (update) =>
            Object.assign(progress, update),
          )
            .then((d) => {
              stopTicker();
              if (!aborted) done(d);
            })
            .catch((err) => {
              stopTicker();
              console.error(
                "session-breakdown: failed to analyze sessions",
                err,
              );
              if (!aborted) done(null);
            });

          return loader;
        },
      );

      if (!data) {
        ctx.ui.notify(
          aborted ? "Cancelled" : "Failed to analyze sessions",
          aborted ? "info" : "error",
        );
        return;
      }

      await ctx.ui.custom<void>(
        (tui, theme, _kb, done) => {
          return new BreakdownComponent(data, tui, done, theme);
        },
        {
          overlay: true,
          overlayOptions: {
            anchor: "center",
            width: "90%",
            minWidth: 60,
            maxHeight: "85%",
          },
        },
      );
    },
  });
}
