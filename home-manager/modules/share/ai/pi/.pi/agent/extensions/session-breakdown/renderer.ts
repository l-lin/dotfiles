import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import type {
  ModelKey,
  CwdKey,
  DowKey,
  TodKey,
  BreakdownView,
  DayAgg,
  RangeAgg,
  RGB,
  MeasurementMode,
} from "./types.js";
import {
  DEFAULT_BG,
  EMPTY_CELL_BG,
  DOW_NAMES,
  TOD_BUCKETS,
  LIGHT_BG,
  LIGHT_EMPTY_CELL_BG,
} from "./constants.js";
import {
  ansiBg,
  bold,
  dim,
  formatCount,
  formatUsd,
  mixRgb,
  padLeft,
  padRight,
  clamp01,
} from "./color-utils.js";
import {
  addDaysLocal,
  countDaysInclusiveLocal,
  mondayIndex,
  toLocalDayKey,
} from "./date-utils.js";
import {
  dayMixedColor,
  graphMetricForRange,
  sortMapByValueDesc,
} from "./aggregation.js";

export { graphMetricForRange };

/**
 * Abbreviate a path for display. Replace home dir with ~, and truncate with … if needed.
 */
function abbreviatePath(p: string, maxWidth = 40): string {
  // We use process.env.HOME as a portable substitute for os.homedir() to avoid importing os.
  const home = process.env.HOME ?? "";
  let display = p;
  if (home && display.startsWith(home)) {
    display = "~" + display.slice(home.length);
  }
  if (display.length <= maxWidth) return display;

  const parts = display.split("/").filter(Boolean);
  // Preserve leading "/" for absolute paths that didn't match HOME
  const leadingSlash = display.startsWith("/") ? "/" : "";
  const prefix = leadingSlash + parts[0]; // e.g. "~" or "/var"

  if (parts.length <= 2) {
    // Can't shorten further; hard-truncate with ellipsis
    return display.slice(0, maxWidth - 1) + "…";
  }

  for (let keep = parts.length - 1; keep >= 1; keep--) {
    const tail = parts.slice(parts.length - keep);
    const candidate = prefix + "/…/" + tail.join("/");
    if (candidate.length <= maxWidth || keep === 1) return candidate;
  }
  return display;
}

export function weeksForRange(range: RangeAgg): number {
  const days = range.days;
  const start = days[0].date;
  const end = days[days.length - 1].date;
  const gridStart = addDaysLocal(start, -mondayIndex(start));
  const gridEnd = addDaysLocal(end, 6 - mondayIndex(end));
  const totalGridDays = countDaysInclusiveLocal(gridStart, gridEnd);
  return Math.ceil(totalGridDays / 7);
}

export function renderGraphLines(
  range: RangeAgg,
  colorMap: Map<string, RGB>,
  otherColor: RGB,
  mode: MeasurementMode,
  options?: {
    cellWidth?: number;
    gap?: number;
    bgColor?: RGB;
    emptyCellBg?: RGB;
  },
  view: BreakdownView = "model",
): string[] {
  const days = range.days;
  const start = days[0].date;
  const end = days[days.length - 1].date;

  const gridStart = addDaysLocal(start, -mondayIndex(start));
  const gridEnd = addDaysLocal(end, 6 - mondayIndex(end));
  const totalGridDays = countDaysInclusiveLocal(gridStart, gridEnd);
  const weeks = Math.ceil(totalGridDays / 7);

  const cellWidth = Math.max(1, Math.floor(options?.cellWidth ?? 1));
  const gap = Math.max(0, Math.floor(options?.gap ?? 1));
  const block = " ".repeat(cellWidth);
  const gapStr = " ".repeat(gap);

  const metric = graphMetricForRange(range, mode);
  const denom = metric.denom;

  // Label only Mon/Wed/Fri like GitHub (saves space)
  const labelByRow = new Map<number, string>([
    [0, "Mon"],
    [2, "Wed"],
    [4, "Fri"],
  ]);

  const lines: string[] = [];
  for (let row = 0; row < 7; row++) {
    const label = labelByRow.get(row);
    let line = label ? padRight(label, 3) + " " : "    ";

    for (let w = 0; w < weeks; w++) {
      const cellDate = addDaysLocal(gridStart, w * 7 + row);
      const inRange = cellDate >= start && cellDate <= end;
      const colGap = w < weeks - 1 ? gapStr : "";
      if (!inRange) {
        line += " ".repeat(cellWidth) + colGap;
        continue;
      }

      const key = toLocalDayKey(cellDate);
      const day = range.dayByKey.get(key);
      const value =
        metric.kind === "tokens"
          ? (day?.tokens ?? 0)
          : metric.kind === "messages"
            ? (day?.messages ?? 0)
            : (day?.sessions ?? 0);

      if (!day || value <= 0) {
        line += ansiBg(options?.emptyCellBg ?? EMPTY_CELL_BG, block) + colGap;
        continue;
      }

      const hue = dayMixedColor(day, colorMap, otherColor, mode, view);
      let t = denom > 0 ? Math.log1p(value) / denom : 0;
      t = clamp01(t);
      const minVisible = 0.45;
      const intensity = minVisible + (1 - minVisible) * t;
      const baseBg = options?.bgColor ?? DEFAULT_BG;
      const rgb = mixRgb(baseBg, hue, intensity);
      line += ansiBg(rgb, block) + colGap;
    }

    lines.push(line);
  }

  return lines;
}

export function renderDowDistributionLines(
  range: RangeAgg,
  mode: MeasurementMode,
  dowColors: Map<DowKey, RGB>,
  width: number,
  bgColor?: RGB,
  emptyCellBg?: RGB,
): string[] {
  const metric = graphMetricForRange(range, mode);
  const kind = metric.kind;
  const perDow =
    kind === "tokens"
      ? range.dowTokens
      : kind === "messages"
        ? range.dowMessages
        : range.dowSessions;
  const total =
    kind === "tokens"
      ? range.totalTokens
      : kind === "messages"
        ? range.totalMessages
        : range.sessions;

  const dayWidth = 3;
  const pctWidth = 4; // "100%"
  const valueWidth = kind === "tokens" ? 10 : 8;
  const showValue = width >= dayWidth + 1 + 10 + 1 + pctWidth + 1 + valueWidth;
  const fixedWidth =
    dayWidth + 1 + 1 + pctWidth + (showValue ? 1 + valueWidth : 0);
  // Cap bar width to keep the chart compact regardless of terminal width
  const MAX_BAR_WIDTH = 40;
  const barWidth = Math.min(MAX_BAR_WIDTH, Math.max(1, width - fixedWidth));
  const baseBg = bgColor ?? DEFAULT_BG;
  const emptyBg = emptyCellBg ?? EMPTY_CELL_BG;
  const fallbackColor: RGB = { r: 160, g: 160, b: 160 };

  const lines: string[] = [];
  for (const dow of DOW_NAMES) {
    const value = perDow.get(dow) ?? 0;
    const share = total > 0 ? value / total : 0;
    let filled = share > 0 ? Math.round(share * barWidth) : 0;
    if (share > 0) filled = Math.max(1, filled);
    filled = Math.min(barWidth, filled);
    const empty = Math.max(0, barWidth - filled);

    const color = dowColors.get(dow) ?? fallbackColor;
    const filledBar =
      filled > 0 ? ansiBg(mixRgb(baseBg, color, 0.85), " ".repeat(filled)) : "";
    const emptyBar = empty > 0 ? ansiBg(emptyBg, " ".repeat(empty)) : "";
    const pct = padLeft(`${Math.round(share * 100)}%`, pctWidth);

    let line = `${padRight(dow, dayWidth)} ${filledBar}${emptyBar} ${pct}`;
    if (showValue) line += ` ${padLeft(formatCount(value), valueWidth)}`;
    lines.push(line);
  }

  return lines;
}

function displayModelName(modelKey: string): string {
  const idx = modelKey.indexOf("/");
  return idx === -1 ? modelKey : modelKey.slice(idx + 1);
}

export function renderLegendItems(
  modelColors: Map<ModelKey, RGB>,
  orderedModels: ModelKey[],
  otherColor: RGB,
  bgBase?: RGB,
): string[] {
  const items: string[] = [];
  for (const mk of orderedModels) {
    const c = modelColors.get(mk);
    if (!c) continue;
    const base = bgBase ?? DEFAULT_BG;
    const legendColor = mixRgb(base, c, 0.75);
    items.push(`${ansiBg(legendColor, "  ")} ${displayModelName(mk)}`);
  }
  const otherLegendColor = mixRgb(bgBase ?? DEFAULT_BG, otherColor, 0.75);
  items.push(`${ansiBg(otherLegendColor, "  ")} other`);
  return items;
}

export function renderModelTable(
  range: RangeAgg,
  mode: MeasurementMode,
  today?: DayAgg,
  maxRows = 8,
): string[] {
  const metric = graphMetricForRange(range, mode);
  const kind = metric.kind;

  let perModel: Map<ModelKey, number>;
  let total = 0;
  const label = kind;

  if (kind === "tokens") {
    perModel = range.modelTokens;
    total = range.totalTokens;
  } else if (kind === "messages") {
    perModel = range.modelMessages;
    total = range.totalMessages;
  } else {
    perModel = range.modelSessions;
    total = range.sessions;
  }

  const sorted = sortMapByValueDesc(perModel);
  const rows = sorted.slice(0, maxRows);

  const valueWidth = kind === "tokens" ? 10 : 8;
  const modelWidth = Math.min(
    52,
    Math.max("model".length, ...rows.map((r) => r.key.length)),
  );

  const totalWidth = modelWidth + 2 + valueWidth + 2 + 10 + 2 + 6;
  const divider = "-".repeat(totalWidth);

  const lines: string[] = [];
  lines.push(
    `${padRight("model", modelWidth)}  ${padLeft(label, valueWidth)}  ${padLeft("cost", 10)}  ${padLeft("share", 6)}`,
  );
  lines.push(divider);

  if (today) {
    const todayLabel = bold(padRight("today ★", modelWidth));
    const todayMetricValue =
      kind === "tokens"
        ? today.tokens
        : kind === "messages"
          ? today.messages
          : today.sessions;
    lines.push(
      `${todayLabel}  ${padLeft(formatCount(todayMetricValue), valueWidth)}  ${padLeft(formatUsd(today.totalCost), 10)}  ${padLeft("—", 6)}`,
    );
    lines.push(divider);
  }

  for (const r of rows) {
    const value = perModel.get(r.key) ?? 0;
    const cost = range.modelCost.get(r.key) ?? 0;
    const share = total > 0 ? `${Math.round((value / total) * 100)}%` : "0%";
    lines.push(
      `${padRight(r.key.slice(0, modelWidth), modelWidth)}  ${padLeft(formatCount(value), valueWidth)}  ${padLeft(formatUsd(cost), 10)}  ${padLeft(share, 6)}`,
    );
  }

  if (sorted.length === 0) {
    lines.push(dim("(no model data found)"));
  }

  return lines;
}

export function renderCwdTable(
  range: RangeAgg,
  mode: MeasurementMode,
  maxRows = 8,
): string[] {
  const metric = graphMetricForRange(range, mode);
  const kind = metric.kind;

  let perCwd: Map<CwdKey, number>;
  let total = 0;
  const label = kind;

  if (kind === "tokens") {
    perCwd = range.cwdTokens;
    total = range.totalTokens;
  } else if (kind === "messages") {
    perCwd = range.cwdMessages;
    total = range.totalMessages;
  } else {
    perCwd = range.cwdSessions;
    total = range.sessions;
  }

  const sorted = sortMapByValueDesc(perCwd);
  const rows = sorted.slice(0, maxRows);

  const valueWidth = kind === "tokens" ? 10 : 8;
  const displayPaths = rows.map((r) => abbreviatePath(r.key, 40));
  const cwdWidth = Math.min(
    42,
    Math.max("directory".length, ...displayPaths.map((p) => p.length)),
  );

  const lines: string[] = [];
  lines.push(
    `${padRight("directory", cwdWidth)}  ${padLeft(label, valueWidth)}  ${padLeft("cost", 10)}  ${padLeft("share", 6)}`,
  );
  lines.push(
    `${"-".repeat(cwdWidth)}  ${"-".repeat(valueWidth)}  ${"-".repeat(10)}  ${"-".repeat(6)}`,
  );

  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    const value = perCwd.get(r.key) ?? 0;
    const cost = range.cwdCost.get(r.key) ?? 0;
    const share = total > 0 ? `${Math.round((value / total) * 100)}%` : "0%";
    lines.push(
      `${padRight(displayPaths[i].slice(0, cwdWidth), cwdWidth)}  ${padLeft(formatCount(value), valueWidth)}  ${padLeft(formatUsd(cost), 10)}  ${padLeft(share, 6)}`,
    );
  }

  if (sorted.length === 0) {
    lines.push(dim("(no directory data found)"));
  }

  return lines;
}

export function renderDowTable(
  range: RangeAgg,
  mode: MeasurementMode,
): string[] {
  const metric = graphMetricForRange(range, mode);
  const kind = metric.kind;
  const perDow =
    kind === "tokens"
      ? range.dowTokens
      : kind === "messages"
        ? range.dowMessages
        : range.dowSessions;
  const total =
    kind === "tokens"
      ? range.totalTokens
      : kind === "messages"
        ? range.totalMessages
        : range.sessions;

  const valueWidth = kind === "tokens" ? 10 : 8;
  const dowWidth = 5; // "day  "

  const lines: string[] = [];
  lines.push(
    `${padRight("day", dowWidth)}  ${padLeft(kind, valueWidth)}  ${padLeft("cost", 10)}  ${padLeft("share", 6)}`,
  );
  lines.push(
    `${"-".repeat(dowWidth)}  ${"-".repeat(valueWidth)}  ${"-".repeat(10)}  ${"-".repeat(6)}`,
  );

  for (const dow of DOW_NAMES) {
    const value = perDow.get(dow) ?? 0;
    const cost = range.dowCost.get(dow) ?? 0;
    const share = total > 0 ? `${Math.round((value / total) * 100)}%` : "0%";
    lines.push(
      `${padRight(dow, dowWidth)}  ${padLeft(formatCount(value), valueWidth)}  ${padLeft(formatUsd(cost), 10)}  ${padLeft(share, 6)}`,
    );
  }

  return lines;
}

export function renderTodTable(
  range: RangeAgg,
  mode: MeasurementMode,
): string[] {
  const metric = graphMetricForRange(range, mode);
  const kind = metric.kind;
  const perTod =
    kind === "tokens"
      ? range.todTokens
      : kind === "messages"
        ? range.todMessages
        : range.todSessions;
  const total =
    kind === "tokens"
      ? range.totalTokens
      : kind === "messages"
        ? range.totalMessages
        : range.sessions;

  const valueWidth = kind === "tokens" ? 10 : 8;
  const todWidth = 22; // widest label

  const lines: string[] = [];
  lines.push(
    `${padRight("time of day", todWidth)}  ${padLeft(kind, valueWidth)}  ${padLeft("cost", 10)}  ${padLeft("share", 6)}`,
  );
  lines.push(
    `${"-".repeat(todWidth)}  ${"-".repeat(valueWidth)}  ${"-".repeat(10)}  ${"-".repeat(6)}`,
  );

  for (const b of TOD_BUCKETS) {
    const value = perTod.get(b.key) ?? 0;
    const cost = range.todCost.get(b.key) ?? 0;
    const share = total > 0 ? `${Math.round((value / total) * 100)}%` : "0%";
    lines.push(
      `${padRight(b.label, todWidth)}  ${padLeft(formatCount(value), valueWidth)}  ${padLeft(formatUsd(cost), 10)}  ${padLeft(share, 6)}`,
    );
  }

  return lines;
}

export function rangeSummary(
  range: RangeAgg,
  days: number,
  mode: MeasurementMode,
): string {
  const avg = range.sessions > 0 ? range.totalCost / range.sessions : 0;
  const costPart =
    range.totalCost > 0
      ? `${formatUsd(range.totalCost)} · avg ${formatUsd(avg)}/session`
      : `$0.00`;

  if (mode === "tokens") {
    return `Last ${days} days: ${formatCount(range.sessions)} sessions · ${formatCount(range.totalTokens)} tokens · ${costPart}`;
  }
  if (mode === "messages") {
    return `Last ${days} days: ${formatCount(range.sessions)} sessions · ${formatCount(range.totalMessages)} messages · ${costPart}`;
  }
  return `Last ${days} days: ${formatCount(range.sessions)} sessions · ${costPart}`;
}

export function renderBreakdownBody(
  range: RangeAgg,
  selectedDays: number,
  measurement: MeasurementMode,
  modelColors: Map<ModelKey, RGB>,
  orderedModels: ModelKey[],
  otherColor: RGB,
  isLight: boolean,
  inner: number,
  todayDay: DayAgg | undefined,
  rangeIndex: number,
  view: BreakdownView,
  cwdColors: Map<CwdKey, RGB>,
  orderedCwds: CwdKey[],
  cwdOtherColor: RGB,
  dowColors: Map<DowKey, RGB>,
  _orderedDows: DowKey[],
  todColors: Map<TodKey, RGB>,
  orderedTods: TodKey[],
): string[] {
  const metric = graphMetricForRange(range, measurement);

  const tab = (days: number, idx: number): string => {
    const selected = idx === rangeIndex;
    const label = `${days}d`;
    return selected ? bold(`[${label}]`) : dim(` ${label} `);
  };

  const metricTab = (mode: MeasurementMode, label: string): string => {
    const selected = mode === measurement;
    return selected ? bold(`[${label}]`) : dim(` ${label} `);
  };

  const viewTab = (v: BreakdownView, label: string): string => {
    const selected = v === view;
    return selected ? bold(`[${label}]`) : dim(` ${label} `);
  };

  const tabs =
    `${tab(7, 0)} ${tab(30, 1)} ${tab(90, 2)}  ` +
    `${metricTab("sessions", "sess")} ${metricTab("messages", "msg")} ${metricTab("tokens", "tok")}  ` +
    `${viewTab("model", "model")} ${viewTab("cwd", "cwd")} ${viewTab("dow", "dow")} ${viewTab("tod", "tod")}`;

  const bgBase = isLight ? LIGHT_BG : DEFAULT_BG;
  const emptyCell = isLight ? LIGHT_EMPTY_CELL_BG : EMPTY_CELL_BG;

  const summary = rangeSummary(range, selectedDays, metric.kind);

  const lines: string[] = [];
  lines.push(truncateToWidth(tabs, inner));
  lines.push("");
  lines.push(truncateToWidth(summary, inner));
  lines.push("");

  // ── Graph / distribution section ──────────────────────────────────────────
  if (view === "dow") {
    // Horizontal bar chart: no calendar graph for dow view
    // inner - 1: box() prepends a leading " " to every line, consuming one char of innerW
    const dowLines = renderDowDistributionLines(
      range,
      measurement,
      dowColors,
      inner - 1,
      bgBase,
      emptyCell,
    );
    for (const gl of dowLines) lines.push(truncateToWidth(gl, inner));
  } else {
    // Determine active color map for graph and legend
    let activeColorMap: Map<string, RGB>;
    let activeOtherColor: RGB;
    let legendTitle: string;
    let legendItems: string[];

    if (view === "cwd") {
      activeColorMap = cwdColors;
      activeOtherColor = cwdOtherColor;
      legendTitle = "Top directories (30d palette):";
      legendItems = [];
      for (const cwd of orderedCwds) {
        const c = cwdColors.get(cwd);
        if (!c) continue;
        const lc = mixRgb(bgBase, c, 0.75);
        legendItems.push(`${ansiBg(lc, "  ")} ${abbreviatePath(cwd, 30)}`);
      }
      const otherLc = mixRgb(bgBase, cwdOtherColor, 0.75);
      legendItems.push(`${ansiBg(otherLc, "  ")} other`);
    } else if (view === "tod") {
      activeColorMap = todColors;
      activeOtherColor = { r: 160, g: 160, b: 160 };
      legendTitle = "Time of day:";
      legendItems = [];
      for (const tod of orderedTods) {
        const c = todColors.get(tod);
        if (!c) continue;
        const lc = mixRgb(bgBase, c, 0.75);
        const label = TOD_BUCKETS.find((b) => b.key === tod)?.label ?? tod;
        legendItems.push(`${ansiBg(lc, "  ")} ${label}`);
      }
    } else {
      // model (default)
      activeColorMap = modelColors;
      activeOtherColor = otherColor;
      legendTitle = "Top models (30d palette):";
      legendItems = renderLegendItems(
        modelColors,
        orderedModels,
        otherColor,
        bgBase,
      );
    }

    const maxScale = selectedDays === 7 ? 4 : selectedDays === 30 ? 3 : 2;
    const weeks = weeksForRange(range);
    const leftMargin = 4;
    const gap = 1;
    const graphArea = Math.max(1, inner - leftMargin);
    const idealCellWidth =
      Math.floor((graphArea + gap) / Math.max(1, weeks)) - gap;
    const cellWidth = Math.min(maxScale, Math.max(1, idealCellWidth));

    const graphLines = renderGraphLines(
      range,
      activeColorMap,
      activeOtherColor,
      measurement,
      { cellWidth, gap, bgColor: bgBase, emptyCellBg: emptyCell },
      view,
    );

    const graphWidth = Math.max(0, ...graphLines.map((l) => visibleWidth(l)));
    const sep = 2;
    const legendWidth = inner - graphWidth - sep;
    const showSideLegend = legendWidth >= 22;

    if (showSideLegend) {
      const legendBlock: string[] = [dim(legendTitle), ...legendItems];
      const maxLegendRows = graphLines.length;
      let legendLines = legendBlock.slice(0, maxLegendRows);
      if (legendBlock.length > maxLegendRows) {
        const remaining = legendBlock.length - (maxLegendRows - 1);
        legendLines = [
          ...legendBlock.slice(0, maxLegendRows - 1),
          dim(`+${remaining} more`),
        ];
      }
      while (legendLines.length < graphLines.length) legendLines.push("");

      const padRightAnsi = (s: string, target: number): string => {
        const w = visibleWidth(s);
        return w >= target ? s : s + " ".repeat(target - w);
      };

      for (let i = 0; i < graphLines.length; i++) {
        const left = padRightAnsi(graphLines[i] ?? "", graphWidth);
        const right = truncateToWidth(
          legendLines[i] ?? "",
          Math.max(0, legendWidth),
        );
        lines.push(truncateToWidth(left + " ".repeat(sep) + right, inner));
      }
    } else {
      for (const gl of graphLines) lines.push(truncateToWidth(gl, inner));
      lines.push("");
      lines.push(truncateToWidth(dim(legendTitle), inner));
      for (const it of legendItems) lines.push(truncateToWidth(it, inner));
    }
  }

  // ── Table section ─────────────────────────────────────────────────────────
  lines.push("");
  const tableLines =
    view === "model"
      ? renderModelTable(range, metric.kind, todayDay, 8)
      : view === "cwd"
        ? renderCwdTable(range, metric.kind, 8)
        : view === "dow"
          ? renderDowTable(range, metric.kind)
          : renderTodTable(range, metric.kind);

  for (const tl of tableLines) lines.push(truncateToWidth(tl, inner));

  return lines;
}
