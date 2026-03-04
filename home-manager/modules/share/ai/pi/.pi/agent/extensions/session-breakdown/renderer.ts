import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import type {
  ModelKey,
  DayAgg,
  RangeAgg,
  RGB,
  MeasurementMode,
} from "./types.js";
import { DEFAULT_BG, EMPTY_CELL_BG } from "./constants.js";
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
  modelColors: Map<ModelKey, RGB>,
  otherColor: RGB,
  mode: MeasurementMode,
  options?: {
    cellWidth?: number;
    gap?: number;
    bgColor?: RGB;
    emptyCellBg?: RGB;
  },
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
  // Use spaces colored via background so cells render correctly on light/dark terminals
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

      const hue = dayMixedColor(day, modelColors, otherColor, mode);
      let t = denom > 0 ? Math.log1p(value) / denom : 0;
      t = clamp01(t);
      const minVisible = 0.2;
      const intensity = minVisible + (1 - minVisible) * t;
      const baseBg = options?.bgColor ?? DEFAULT_BG;
      const rgb = mixRgb(baseBg, hue, intensity);
      line += ansiBg(rgb, block) + colGap;
    }

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
    // Show a small background-colored block that matches how graph cells are mixed with the
    // theme background. Use a slightly strong intensity for the legend.
    const base = bgBase ?? DEFAULT_BG;
    const legendColor = mixRgb(base, c, 0.9);
    items.push(`${ansiBg(legendColor, "  ")} ${displayModelName(mk)}`);
  }
  const otherLegendColor = mixRgb(bgBase ?? DEFAULT_BG, otherColor, 0.9);
  items.push(`${ansiBg(otherLegendColor, "  ")} other`);
  return items;
}

export function renderModelTable(
  range: RangeAgg,
  mode: MeasurementMode,
  today?: DayAgg,
  maxRows = 8,
): string[] {
  // Keep this relatively narrow: model + selected metric + cost + share.
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

  // Today row: pinned at top, aligned to the same columns as the model rows.
  if (today) {
    const todayLabel = bold(padRight("today ★", modelWidth));
    // Primary metric column: show the relevant count for the current kind
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

export function rangeSummary(
  range: RangeAgg,
  days: number,
  mode: MeasurementMode,
): string {
  const avg = range.sessions > 0 ? range.totalCost / range.sessions : 0;
  const costPart =
    range.totalCost > 0
      ? `${formatUsd(range.totalCost)} · avg ${formatUsd(avg)}/session`
      : `$0.0000`;

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

  const tabs =
    `${tab(7, 0)} ${tab(30, 1)} ${tab(90, 2)}  ` +
    `${metricTab("sessions", "sess")} ${metricTab("messages", "msg")} ${metricTab("tokens", "tok")}`;

  const bgBase = isLight ? { r: 255, g: 255, b: 255 } : DEFAULT_BG;
  const emptyCell = isLight ? { r: 255, g: 255, b: 255 } : EMPTY_CELL_BG;

  const legendItems = renderLegendItems(
    modelColors,
    orderedModels,
    otherColor,
    bgBase,
  );

  const summary =
    rangeSummary(range, selectedDays, metric.kind) +
    dim(`   (graph: ${metric.kind}/day)`);

  const maxScale = selectedDays === 7 ? 4 : selectedDays === 30 ? 3 : 2;
  const weeks = weeksForRange(range);
  const leftMargin = 4; // "Mon " (or 4 spaces)
  const gap = 1;
  const graphArea = Math.max(1, inner - leftMargin);
  const idealCellWidth =
    Math.floor((graphArea + gap) / Math.max(1, weeks)) - gap;
  const cellWidth = Math.min(maxScale, Math.max(1, idealCellWidth));

  const graphLines = renderGraphLines(
    range,
    modelColors,
    otherColor,
    measurement,
    {
      cellWidth,
      gap,
      bgColor: bgBase,
      emptyCellBg: emptyCell,
    },
  );

  const tableLines = renderModelTable(range, metric.kind, todayDay, 8);

  const lines: string[] = [];
  lines.push(truncateToWidth(tabs, inner));
  lines.push("");
  lines.push(truncateToWidth(summary, inner));
  lines.push("");

  // Render legend on the RIGHT of the graph if there is space.
  const graphWidth = Math.max(0, ...graphLines.map((l) => visibleWidth(l)));
  const sep = 2;
  const legendWidth = inner - graphWidth - sep;
  const showSideLegend = legendWidth >= 22;

  if (showSideLegend) {
    const legendBlock: string[] = [];
    legendBlock.push(dim("Top models (30d palette):"));
    legendBlock.push(...legendItems);
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
    lines.push(truncateToWidth(dim("Top models (30d palette):"), inner));
    for (const it of legendItems) lines.push(truncateToWidth(it, inner));
  }

  lines.push("");
  for (const tl of tableLines) lines.push(truncateToWidth(tl, inner));

  return lines;
}
