/**
 * A nicer footer
 */

import type { ExtensionAPI, ReadonlyFooterDataProvider, Theme } from "@mariozechner/pi-coding-agent";
import type { Component, TUI } from "@mariozechner/pi-tui";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

function formatTokens(count: number): string {
  if (count < 1_000) return count.toString();
  if (count < 10_000) return `${(count / 1_000).toFixed(1)}k`;
  if (count < 1_000_000) return `${Math.round(count / 1_000)}k`;
  if (count < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
  return `${Math.round(count / 1_000_000)}M`;
}

function colorContext(percent: number, text: string, theme: Theme): string {
  if (percent > 60) return theme.fg("error", text);
  if (percent > 40) return theme.fg("warning", text);
  return theme.fg("dim", text);
}

function colorCost(amount: number, text: string, theme: Theme): string {
  if (amount > 5) return theme.fg("error", text);
  if (amount > 3) return theme.fg("warning", text);
  return theme.fg("dim", text);
}

type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh";

function colorThinking(level: ThinkingLevel, text: string, theme: Theme): string {
  if (level === "high" || level === "xhigh") return theme.fg("error", text);
  if (level === "medium") return theme.fg("warning", text);
  return theme.fg("dim", text);
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (!ctx.hasUI) return;

    ctx.ui.setFooter((_tui: TUI, theme: Theme, footerData: ReadonlyFooterDataProvider): Component => {
      return {
        render(width: number): string[] {
          const t = theme;

          // ── Line 1: CWD (left) + git branch (right) ──────────────────────
          let pwd = process.cwd();
          const home = process.env.HOME ?? process.env.USERPROFILE ?? "";
          if (home && pwd.startsWith(home)) pwd = `~${pwd.slice(home.length)}`;

          const branch = footerData.getGitBranch();
          const cwdLeft = t.fg("dim", ` ${pwd}`);
          const branchRight = branch ? t.fg("dim", `󰘬 ${branch}`) : "";

          let cwdLine: string;
          if (branch) {
            const cwdWidth = visibleWidth(cwdLeft);
            const branchWidth = visibleWidth(branchRight);
            if (cwdWidth + branchWidth <= width) {
              const padding = " ".repeat(width - cwdWidth - branchWidth);
              cwdLine = cwdLeft + padding + branchRight;
            } else {
              const available = Math.max(1, width - branchWidth - 1);
              cwdLine = truncateToWidth(cwdLeft, available, t.fg("dim", "…")) + " " + branchRight;
            }
          } else {
            cwdLine = truncateToWidth(cwdLeft, width, t.fg("dim", "…"));
          }

          // ── Line 2: stats ─────────────────────────────────────────────────

          // Context usage
          const ctxUsage = ctx.getContextUsage();
          const contextWindow = ctxUsage?.contextWindow ?? 0;
          const percentValue = ctxUsage?.percent ?? 0;
          const percentStr = ctxUsage?.percent != null ? percentValue.toFixed(1) : "?";
          const contextDisplay = ` ${percentStr}%/${formatTokens(contextWindow)}`;
          const coloredContext = colorContext(percentValue, contextDisplay, t);

          // Accumulate spend from session entries
          let spend = 0;
          for (const entry of ctx.sessionManager.getEntries()) {
            if (entry.type === "message" && (entry as any).message?.role === "assistant") {
              const u = (entry as any).message?.usage;
              if (u) spend += u.cost?.total ?? 0;
            }
          }

          // Model & provider
          const model = ctx.model;
          const modelStr = model ? `${model.provider}/${model.id}` : "no-model";

          // Left section
          const leftParts: string[] = [coloredContext];
          if (spend > 0) leftParts.push(colorCost(spend, ` $${spend.toFixed(3)}`, t));

          const leftStr = leftParts.join(" ");

          // Right section
          const rightParts: string[] = [];
          // Thinking level (only shown when model supports reasoning and thinking is on)
          const thinkingLevel = pi.getThinkingLevel() as ThinkingLevel;
          const thinkingStr =
            model?.reasoning && thinkingLevel !== "off"
              ? colorThinking(thinkingLevel, `󰧑 ${thinkingLevel}`, t)
              : null;
          if (thinkingStr) rightParts.push(thinkingStr);
          rightParts.push(t.fg("dim", `󰚩 ${modelStr}`));
          const rightStr = rightParts.join(" ");

          // Compose with right-alignment
          const leftWidth = visibleWidth(leftStr);
          const rightWidth = visibleWidth(rightStr);

          let statsLine: string;
          if (leftWidth + 2 + rightWidth <= width) {
            const padding = " ".repeat(width - leftWidth - rightWidth);
            statsLine = leftStr + padding + rightStr;
          } else {
            statsLine = truncateToWidth(`${leftStr}  ${rightStr}`, width, t.fg("dim", "…"));
          }

          // ── Optional extension status line ────────────────────────────────
          const lines: string[] = [statsLine, cwdLine];

          const statuses = footerData.getExtensionStatuses();
          if (statuses.size > 0) {
            const statusLine = Array.from(statuses.entries())
              .sort(([a], [b]) => a.localeCompare(b))
              .map(([, v]) => v.replace(/[\r\n\t]/g, " ").trim())
              .join("  ");
            lines.push(truncateToWidth(statusLine, width, t.fg("dim", "…")));
          }

          return lines;
        },

        dispose() {},
      };
    });
  });
}
