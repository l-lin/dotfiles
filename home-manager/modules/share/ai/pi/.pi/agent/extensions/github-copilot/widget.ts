// ============================================================================
// GitHub Copilot Extension — Usage Widget Rendering
// ============================================================================

import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { AuthStatus, UsageData } from "./types.js";

export const WIDGET_ID = "copilot-usage";
export const WIDGET_PLACEMENT = { placement: "aboveEditor" as const };

const BAR_WIDTH = 20;
const USAGE_WARNING_THRESHOLD = 70;
const USAGE_ERROR_THRESHOLD = 90;

function renderProgressBar(
  current: number,
  max: number,
  width: number,
  theme: ExtensionContext["ui"]["theme"],
  colorize: boolean,
): string {
  const ratio = max > 0 ? Math.max(0, Math.min(current / max, 1)) : 0;
  const filled = Math.round(ratio * width);
  const empty = width - filled;
  const bar = "█".repeat(filled) + "░".repeat(empty);

  if (!colorize) return bar;

  const percent = ratio * 100;
  if (percent >= USAGE_ERROR_THRESHOLD) return theme.fg("error", bar);
  if (percent >= USAGE_WARNING_THRESHOLD) return theme.fg("warning", bar);
  return theme.fg("success", bar);
}

function getDaysRemaining(resetDateStr: string): number {
  if (!resetDateStr) return 0;
  const parts = resetDateStr.split("-").map(Number);
  if (parts.length !== 3 || parts.some(isNaN)) return 0;
  const [year, month, day] = parts;
  const resetDate = new Date(year, month - 1, day);
  const diffMs = resetDate.getTime() - Date.now();
  return Math.max(0, Math.ceil(diffMs / (1000 * 60 * 60 * 24)));
}

function getMonthProgress() {
  const now = new Date(Date.now());
  const currentDay = now.getDate();
  const daysInMonth = new Date(
    now.getFullYear(),
    now.getMonth() + 1,
    0,
  ).getDate();
  const completedDays = Math.max(0, currentDay - 1);
  const totalProgressDays = Math.max(1, daysInMonth - 1);
  const percentage = Math.round((completedDays / totalProgressDays) * 100);

  return { completedDays, totalProgressDays, percentage };
}

export function updateWidget(
  ctx: ExtensionContext,
  usageData: UsageData | null,
  authStatus: AuthStatus,
  sessionDelta: number = 0,
): void {
  const theme = ctx.ui.theme;

  if (!authStatus.hasToken) {
    ctx.ui.setWidget(
      WIDGET_ID,
      [
        theme.fg("error", " Copilot: ") +
          theme.fg("dim", authStatus.error || "No token"),
      ],
      WIDGET_PLACEMENT,
    );
    return;
  }

  if (!usageData) {
    ctx.ui.setWidget(
      WIDGET_ID,
      [
        theme.fg("warning", " Copilot: ") +
          theme.fg("dim", "Failed to fetch usage data"),
      ],
      WIDGET_PLACEMENT,
    );
    return;
  }

  if (usageData.unlimited) {
    ctx.ui.setWidget(
      WIDGET_ID,
      [
        theme.fg("success", "  Copilot: ") +
          theme.fg("dim", "Unlimited premium requests"),
      ],
      WIDGET_PLACEMENT,
    );
    return;
  }

  const { used, quota, resetDate } = usageData;
  const percent = quota > 0 ? ((used / quota) * 100).toFixed(1) : "0.0";
  const usageBar = renderProgressBar(used, quota, BAR_WIDTH, theme, true);
  const deltaText =
    sessionDelta > 0 ? theme.fg("error", ` +${sessionDelta}`) : "";
  const usagePart = `${usageBar} ${used}/${quota} (${percent}%)${deltaText}`;

  const daysRemaining = getDaysRemaining(resetDate);
  const monthProgress = getMonthProgress();
  const daysBar = renderProgressBar(
    monthProgress.completedDays,
    monthProgress.totalProgressDays,
    BAR_WIDTH,
    theme,
    false,
  );
  const daysPart = `${daysBar} ${daysRemaining}d left (${monthProgress.percentage}%)`;

  ctx.ui.setWidget(WIDGET_ID, [`${usagePart} ${daysPart}`], WIDGET_PLACEMENT);
}
