import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import { BorderedLoader } from "@mariozechner/pi-coding-agent";
import { formatCount } from "../session-breakdown/color-utils.js";
import {
  computeSkillBreakdown,
  rangeSummary,
  renderTopSkillsText,
} from "./aggregation.js";
import { SkillBreakdownComponent } from "./component.js";
import { LOADER_BASE_MESSAGE } from "./constants.js";
import type {
  SkillBreakdownData,
  SkillBreakdownProgressState,
} from "./types.js";

function setBorderedLoaderMessage(
  loader: BorderedLoader,
  message: string,
): void {
  const innerLoader = (loader as any)["loader"];
  if (innerLoader && typeof innerLoader.setMessage === "function") {
    innerLoader.setMessage(message);
  }
}

export default function skillBreakdownExtension(pi: ExtensionAPI) {
  pi.registerCommand("cmd:skill-breakdown", {
    description:
      "Interactive breakdown of skill usage over the last 7, 30, or 90 days",
    handler: async (_args: string, ctx: ExtensionContext) => {
      if (!ctx.hasUI) {
        const data = await computeSkillBreakdown();
        const range = data.ranges.get(30)!;
        const content = [
          rangeSummary(range, 30),
          ...renderTopSkillsText(range),
        ].join("\n");

        pi.sendMessage(
          {
            customType: "skill-breakdown",
            content,
            display: true,
          },
          { triggerTurn: false },
        );
        return;
      }

      let aborted = false;
      const data = await ctx.ui.custom<SkillBreakdownData | null>(
        (tui, theme, _kb, done) => {
          const loader = new BorderedLoader(tui, theme, LOADER_BASE_MESSAGE);
          const startedAt = Date.now();
          const progress: SkillBreakdownProgressState = {
            phase: "scan",
            foundFiles: 0,
            parsedFiles: 0,
            totalFiles: 0,
            currentFile: undefined,
          };

          const renderMessage = (): string => {
            const elapsed = ((Date.now() - startedAt) / 1000).toFixed(1);
            if (progress.phase === "scan") {
              return `${LOADER_BASE_MESSAGE}  scanning (${formatCount(progress.foundFiles)} files) · ${elapsed}s`;
            }
            if (progress.phase === "parse") {
              return `${LOADER_BASE_MESSAGE}  parsing (${formatCount(progress.parsedFiles)}/${formatCount(progress.totalFiles)}) · ${elapsed}s`;
            }
            return `${LOADER_BASE_MESSAGE}  finalizing · ${elapsed}s`;
          };

          let intervalId: NodeJS.Timeout | null = null;
          const stopTicker = () => {
            if (!intervalId) return;
            clearInterval(intervalId);
            intervalId = null;
          };

          setBorderedLoaderMessage(loader, renderMessage());
          intervalId = setInterval(() => {
            setBorderedLoaderMessage(loader, renderMessage());
          }, 500);

          loader.onAbort = () => {
            aborted = true;
            stopTicker();
            done(null);
          };

          computeSkillBreakdown({
            signal: loader.signal,
            onProgress: (update) => Object.assign(progress, update),
          })
            .then((breakdown) => {
              stopTicker();
              if (!aborted) done(breakdown);
            })
            .catch((error) => {
              stopTicker();
              console.error(
                "skill-breakdown: failed to analyze skill usage",
                error,
              );
              if (!aborted) done(null);
            });

          return loader;
        },
      );

      if (!data) {
        ctx.ui.notify(
          aborted ? "Cancelled" : "Failed to analyze skill usage",
          aborted ? "info" : "error",
        );
        return;
      }

      await ctx.ui.custom<void>(
        (tui, theme, kb, done) => {
          return new SkillBreakdownComponent(data, tui, done, theme, kb);
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
