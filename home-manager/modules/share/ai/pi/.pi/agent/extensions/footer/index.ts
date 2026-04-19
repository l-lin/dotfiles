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

        return {
          render(width: number): string[] {
            const lines: string[] = [];

            // Line 1: Stats (context, tools, cost | thinking, model)
            lines.push(buildStatsLine(width, theme, ctx, pi));

            // Line 2: Directory and git branch (with sandbox and damage-control status icons)
            lines.push(
              buildDirectoryLine(width, theme, footerData, runtimeState),
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
