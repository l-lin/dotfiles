import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import type { BreakdownData, BreakdownProgressState } from "./types.js";

type SessionBreakdownRuntime = {
  BorderedLoader: (typeof import("@earendil-works/pi-coding-agent"))["BorderedLoader"];
  formatCount: (typeof import("./color-utils.js"))["formatCount"];
  computeBreakdown: (typeof import("./aggregation.js"))["computeBreakdown"];
  rangeSummary: (typeof import("./renderer.js"))["rangeSummary"];
  BreakdownComponent: (typeof import("./component.js"))["BreakdownComponent"];
};

let runtimePromise: Promise<SessionBreakdownRuntime> | undefined;

function loadRuntime(): Promise<SessionBreakdownRuntime> {
  if (runtimePromise) return runtimePromise;

  const loading = Promise.all([
    import("@earendil-works/pi-coding-agent"),
    import("./color-utils.js"),
    import("./aggregation.js"),
    import("./renderer.js"),
    import("./component.js"),
  ]).then(([agent, colorUtils, aggregation, renderer, component]) => ({
    BorderedLoader: agent.BorderedLoader,
    formatCount: colorUtils.formatCount,
    computeBreakdown: aggregation.computeBreakdown,
    rangeSummary: renderer.rangeSummary,
    BreakdownComponent: component.BreakdownComponent,
  }));

  const promise = loading.catch((error) => {
    runtimePromise = undefined;
    throw error;
  });
  runtimePromise = promise;
  return promise;
}

/** BorderedLoader wraps an inner Loader that supports setMessage() but doesn't expose it publicly. */
function setBorderedLoaderMessage(
  loader: InstanceType<SessionBreakdownRuntime["BorderedLoader"]>,
  message: string,
) {
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
      const runtime = await loadRuntime();
      const {
        BorderedLoader,
        BreakdownComponent,
        computeBreakdown,
        formatCount,
        rangeSummary,
      } = runtime;

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
            width: "50%",
            minWidth: 60,
            maxHeight: "85%",
          },
        },
      );
    },
  });
}
