/**
 * A nicer footer
 *
 * Dependencies:
 *
 * - ../sandbox/
 */

import type {
  ExtensionAPI,
  ReadonlyFooterDataProvider,
  Theme,
} from "@earendil-works/pi-coding-agent";
import type { Component, TUI } from "@earendil-works/pi-tui";

// defer footer formatting modules until the TUI needs the custom footer.
type FooterRuntime = {
  buildStatsLine: (typeof import("./lines.js"))["buildStatsLine"];
  buildDirectoryLine: (typeof import("./lines.js"))["buildDirectoryLine"];
  buildStatusLine: (typeof import("./lines.js"))["buildStatusLine"];
};

let footerRuntime: FooterRuntime | undefined;
let footerRuntimePromise: Promise<FooterRuntime> | undefined;

function loadFooterRuntime(): Promise<FooterRuntime> {
  if (footerRuntimePromise) return footerRuntimePromise;

  const loading = import("./lines.js").then(
    ({ buildStatsLine, buildDirectoryLine, buildStatusLine }) => {
      footerRuntime = { buildStatsLine, buildDirectoryLine, buildStatusLine };
      return footerRuntime;
    },
  );

  footerRuntimePromise = loading.catch((error) => {
    footerRuntimePromise = undefined;
    throw error;
  });
  return footerRuntimePromise;
}

export default function (pi: ExtensionAPI) {
  let currentTui: TUI | undefined;
  const runtimeState = {
    sandboxEnabled: false,
    damageControlEnabled: false,
  };

  pi.events.on("custom-tool:changed", () => {
    currentTui?.requestRender();
  });

  pi.events.on("sandbox:state-changed", (enabled: unknown) => {
    runtimeState.sandboxEnabled = enabled === true;
    currentTui?.requestRender();
  });

  pi.events.on("damage-control:state-changed", (enabled: unknown) => {
    runtimeState.damageControlEnabled = enabled === true;
    currentTui?.requestRender();
  });

  pi.on("session_start", (_event, ctx) => {
    if (!ctx.hasUI) return;

    ctx.ui.setFooter(
      (
        tui: TUI,
        theme: Theme,
        footerData: ReadonlyFooterDataProvider,
      ): Component => {
        currentTui = tui;
        void loadFooterRuntime().then(
          () => tui.requestRender(),
          () => tui.requestRender(),
        );

        return {
          render(width: number): string[] {
            const runtime = footerRuntime;
            if (!runtime) return [];

            const lines: string[] = [];

            // Line 1: Stats (context, tools, cost | thinking, model)
            lines.push(runtime.buildStatsLine(width, theme, ctx, pi));

            // Line 2: Directory and git branch (with sandbox and damage-control status icons)
            lines.push(
              runtime.buildDirectoryLine(
                width,
                theme,
                footerData,
                runtimeState,
              ),
            );

            // Line 3: Extension statuses (if any)
            const statusLine = runtime.buildStatusLine(
              width,
              theme,
              footerData,
            );
            if (statusLine) {
              lines.push(statusLine);
            }

            return lines;
          },
          invalidate() {},
        };
      },
    );
  });
}
