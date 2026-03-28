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
} from "@mariozechner/pi-coding-agent";
import type { Component, TUI } from "@mariozechner/pi-tui";
import {
  buildStatsLine,
  buildDirectoryLine,
  buildStatusLine,
} from "./lines.js";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (!ctx.hasUI) return;

    let currentTui: TUI | undefined;
    let sandboxEnabled = false;

    // Re-render when custom tools change
    pi.events.on("custom-tool:changed", () => {
      currentTui?.requestRender();
    });

    // Re-render when sandbox state changes
    pi.events.on("sandbox:state-changed", (enabled: unknown) => {
      sandboxEnabled = enabled === true;
      currentTui?.requestRender();
    });

    ctx.ui.setFooter(
      (
        tui: TUI,
        theme: Theme,
        footerData: ReadonlyFooterDataProvider,
      ): Component => {
        currentTui = tui;

        return {
          render(width: number): string[] {
            const lines: string[] = [];

            // Line 1: Stats (context, tools, cost | thinking, model)
            lines.push(buildStatsLine(width, theme, ctx, pi));

            // Line 2: Directory and git branch (with sandbox status icon)
            lines.push(
              buildDirectoryLine(width, theme, footerData, sandboxEnabled),
            );

            // Line 3: Extension statuses (if any)
            const statusLine = buildStatusLine(width, theme, footerData);
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
