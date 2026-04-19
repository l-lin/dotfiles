/**
 * Line building functions
 */

import type {
  ExtensionAPI,
  ReadonlyFooterDataProvider,
  Theme,
} from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import { ICONS, type ThinkingLevel } from "./constants.js";
import {
  formatCurrentDirectory,
  colorByPercent,
  colorByCost,
  colorByThinkingLevel,
} from "./formatting.js";
import {
  getContextData,
  calculateSessionSpend,
  getModelInfo,
  buildToolIcons,
} from "./data.js";

export interface DirectoryLineState {
  sandboxEnabled?: boolean;
  damageControlEnabled?: boolean;
}

export function buildStatsLine(
  width: number,
  theme: Theme,
  ctx: any,
  pi: ExtensionAPI,
): string {
  // Left side: context, tools, cost
  const contextData = getContextData(ctx);
  const leftParts: string[] = [];

  const toolIcons = buildToolIcons(theme);
  if (toolIcons) {
    leftParts.push(toolIcons);
  }

  leftParts.push(" ");

  if (contextData.display) {
    leftParts.push(
      colorByPercent(contextData.percent, contextData.display, theme),
    );
  }

  const spend = calculateSessionSpend(ctx);
  if (spend > 0) {
    leftParts.push(
      colorByCost(spend, `${ICONS["cost"]} $${spend.toFixed(3)}`, theme),
    );
  }

  const leftStr = leftParts.join(" ");

  // Right side: thinking level, model
  const rightParts: string[] = [];
  const thinkingLevel = pi.getThinkingLevel() as ThinkingLevel;
  const model = ctx.model;

  if (model?.reasoning && thinkingLevel !== "off") {
    const thinkingStr = colorByThinkingLevel(
      thinkingLevel,
      `${ICONS["thinking-level"]} ${thinkingLevel}`,
      theme,
    );
    rightParts.push(thinkingStr);
  }

  rightParts.push(theme.fg("dim", `${ICONS["model"]} ${getModelInfo(ctx)}`));
  const rightStr = rightParts.join(" ");

  // Layout
  return buildTwoPartLine(width, theme, leftStr, rightStr);
}

export function buildDirectoryLine(
  width: number,
  theme: Theme,
  footerData: ReadonlyFooterDataProvider,
  state: DirectoryLineState = {},
): string {
  const pwd = formatCurrentDirectory();
  const branch = footerData.getGitBranch();

  const sandboxIcon = state.sandboxEnabled
    ? theme.fg("dim", ICONS["sandbox-enabled"])
    : theme.fg("error", ICONS["sandbox-disabled"]);
  const damageControlIcon = state.damageControlEnabled
    ? theme.fg("dim", ICONS["damage-control-enabled"])
    : theme.fg("error", ICONS["damage-control-disabled"]);
  const directory = theme.fg("dim", `${ICONS["cwd"]} ${pwd}`);
  const cwdLeft = `${sandboxIcon} ${damageControlIcon} ${directory}`;
  const branchRight = branch
    ? theme.fg("dim", `${ICONS["branch"]} ${branch}`)
    : "";

  if (!branch) {
    return truncateToWidth(cwdLeft, width, theme.fg("dim", "…"));
  }

  const cwdWidth = visibleWidth(cwdLeft);
  const branchWidth = visibleWidth(branchRight);

  if (cwdWidth + branchWidth <= width) {
    const padding = " ".repeat(width - cwdWidth - branchWidth);
    return cwdLeft + padding + branchRight;
  }

  const available = Math.max(1, width - branchWidth - 1);
  return (
    truncateToWidth(cwdLeft, available, theme.fg("dim", "…")) +
    " " +
    branchRight
  );
}

export function buildStatusLine(
  width: number,
  theme: Theme,
  footerData: ReadonlyFooterDataProvider,
): string | null {
  const statuses = footerData.getExtensionStatuses();

  if (statuses.size === 0) {
    return null;
  }

  const statusLine = Array.from(statuses.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([, v]) => v.replace(/[\r\n\t]/g, " ").trim())
    .join("  ");

  return truncateToWidth(statusLine, width, theme.fg("dim", "…"));
}

function buildTwoPartLine(
  width: number,
  theme: Theme,
  leftStr: string,
  rightStr: string,
): string {
  const leftWidth = visibleWidth(leftStr);
  const rightWidth = visibleWidth(rightStr);

  if (leftWidth + 2 + rightWidth <= width) {
    const padding = " ".repeat(width - leftWidth - rightWidth);
    return leftStr + padding + rightStr;
  }

  return truncateToWidth(
    `${leftStr}  ${rightStr}`,
    width,
    theme.fg("dim", "…"),
  );
}
