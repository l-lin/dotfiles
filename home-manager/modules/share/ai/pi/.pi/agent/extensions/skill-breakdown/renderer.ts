import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import {
  ansiBg,
  bold,
  clamp01,
  dim,
  formatCount,
  mixRgb,
  padLeft,
  padRight,
  weightedMix,
} from "../session-breakdown/color-utils.js";
import {
  addDaysLocal,
  countDaysInclusiveLocal,
  mondayIndex,
  toLocalDayKey,
} from "../session-breakdown/date-utils.js";
import {
  ALL_MODELS_LABEL,
  DEFAULT_BG,
  EMPTY_CELL_BG,
  LIGHT_BG,
  LIGHT_EMPTY_CELL_BG,
  TOP_SKILLS_LIMIT,
} from "./constants.js";
import {
  formatShare,
  getOrderedModelsForSkill,
  getProjectCountsForSkill,
  getSkillCount,
  rangeSummary,
  sortMapByValueDesc,
} from "./aggregation.js";
import { findSkillMatches } from "./search.js";
import type {
  ModelKey,
  RGB,
  SkillBreakdownData,
  SkillBreakdownView,
  SkillDayAgg,
  SkillName,
  SkillRangeAgg,
} from "./types.js";

function abbreviateProjectPath(projectPath: string, maxWidth = 40): string {
  const home = process.env.HOME ?? "";
  let displayPath = projectPath;
  if (home && displayPath.startsWith(home)) {
    displayPath = "~" + displayPath.slice(home.length);
  }
  if (displayPath.length <= maxWidth) return displayPath;

  const parts = displayPath.split("/").filter(Boolean);
  const leadingSlash = displayPath.startsWith("/") ? "/" : "";
  const prefix = leadingSlash + (parts[0] ?? "");
  if (parts.length <= 2) return displayPath.slice(0, maxWidth - 1) + "…";

  for (let keep = parts.length - 1; keep >= 1; keep--) {
    const tail = parts.slice(parts.length - keep);
    const candidate = `${prefix}/…/${tail.join("/")}`;
    if (candidate.length <= maxWidth || keep === 1) return candidate;
  }

  return displayPath;
}

function dayMixedColor(
  day: SkillDayAgg,
  colorMap: Map<string, RGB>,
  otherColor: RGB,
): RGB {
  const parts: Array<{ color: RGB; weight: number }> = [];
  let otherWeight = 0;

  for (const [skillName, weight] of day.skillCounts.entries()) {
    const color = colorMap.get(skillName);
    if (color) parts.push({ color, weight });
    else otherWeight += weight;
  }

  if (otherWeight > 0) parts.push({ color: otherColor, weight: otherWeight });
  return weightedMix(parts);
}

export function weeksForRange(range: SkillRangeAgg): number {
  const start = range.days[0]!.date;
  const end = range.days[range.days.length - 1]!.date;
  const gridStart = addDaysLocal(start, -mondayIndex(start));
  const gridEnd = addDaysLocal(end, 6 - mondayIndex(end));
  const totalGridDays = countDaysInclusiveLocal(gridStart, gridEnd);
  return Math.ceil(totalGridDays / 7);
}

export function renderGraphLines(
  range: SkillRangeAgg,
  colorMap: Map<string, RGB>,
  otherColor: RGB,
  options?: {
    cellWidth?: number;
    gap?: number;
    bgColor?: RGB;
    emptyCellBg?: RGB;
  },
): string[] {
  const start = range.days[0]!.date;
  const end = range.days[range.days.length - 1]!.date;
  const gridStart = addDaysLocal(start, -mondayIndex(start));
  const gridEnd = addDaysLocal(end, 6 - mondayIndex(end));
  const totalGridDays = countDaysInclusiveLocal(gridStart, gridEnd);
  const weeks = Math.ceil(totalGridDays / 7);

  const cellWidth = Math.max(1, Math.floor(options?.cellWidth ?? 1));
  const gap = Math.max(0, Math.floor(options?.gap ?? 1));
  const block = " ".repeat(cellWidth);
  const gapStr = " ".repeat(gap);
  const maxInvocations = Math.max(
    0,
    ...range.days.map((day) => day.invocations),
  );
  const denom = Math.log1p(maxInvocations);

  const labelByRow = new Map<number, string>([
    [0, "Mon"],
    [2, "Wed"],
    [4, "Fri"],
  ]);

  const lines: string[] = [];
  for (let row = 0; row < 7; row++) {
    const label = labelByRow.get(row);
    let line = label ? `${padRight(label, 3)} ` : "    ";

    for (let week = 0; week < weeks; week++) {
      const cellDate = addDaysLocal(gridStart, week * 7 + row);
      const inRange = cellDate >= start && cellDate <= end;
      const columnGap = week < weeks - 1 ? gapStr : "";

      if (!inRange) {
        line += " ".repeat(cellWidth) + columnGap;
        continue;
      }

      const day = range.dayByKey.get(toLocalDayKey(cellDate));
      const value = day?.invocations ?? 0;
      if (!day || value <= 0) {
        line +=
          ansiBg(options?.emptyCellBg ?? EMPTY_CELL_BG, block) + columnGap;
        continue;
      }

      const hue = dayMixedColor(day, colorMap, otherColor);
      const intensity =
        maxInvocations > 0
          ? 0.45 + 0.55 * clamp01(Math.log1p(value) / denom)
          : 0;
      const background = options?.bgColor ?? DEFAULT_BG;
      line += ansiBg(mixRgb(background, hue, intensity), block) + columnGap;
    }

    lines.push(line);
  }

  return lines;
}

function renderLegendItems(
  data: SkillBreakdownData,
  background: RGB,
): string[] {
  const items: string[] = [];

  for (const skillName of data.palette.orderedSkills) {
    const color = data.palette.skillColors.get(skillName);
    if (!color) continue;
    items.push(`${ansiBg(mixRgb(background, color, 0.75), "  ")} ${skillName}`);
  }

  items.push(
    `${ansiBg(mixRgb(background, data.palette.otherColor, 0.75), "  ")} other`,
  );
  return items;
}

export function renderSkillTable(
  range: SkillRangeAgg,
  maxRows = TOP_SKILLS_LIMIT,
): string[] {
  const rows = sortMapByValueDesc(range.skillCounts).slice(0, maxRows);
  const countWidth = 8;
  const skillWidth = Math.min(
    50,
    Math.max("skill".length, ...rows.map((row) => row.key.length)),
  );

  const lines: string[] = [];
  lines.push(
    `${padRight("skill", skillWidth)}  ${padLeft("count", countWidth)}  ${padLeft("share", 6)}`,
  );
  lines.push(
    `${"-".repeat(skillWidth)}  ${"-".repeat(countWidth)}  ${"-".repeat(6)}`,
  );

  for (const row of rows) {
    lines.push(
      `${padRight(row.key.slice(0, skillWidth), skillWidth)}  ${padLeft(formatCount(row.value), countWidth)}  ${padLeft(formatShare(row.value, range.totalInvocations), 6)}`,
    );
  }

  if (rows.length === 0) {
    lines.push(dim("(no skill activity found)"));
  }

  return lines;
}

function renderSearchBlock(
  range: SkillRangeAgg,
  query: string,
  inner: number,
  selectedSearchIndex: number,
): string[] {
  const matches = findSkillMatches(range, query);
  const lines = [truncateToWidth(`search: ${query || "…"}`, inner)];

  if (matches.length === 0) {
    lines.push(truncateToWidth(dim("No matches. Press esc to cancel."), inner));
    return lines;
  }

  const activeIndex = Math.max(
    0,
    Math.min(selectedSearchIndex, matches.length - 1),
  );

  for (let index = 0; index < matches.length; index++) {
    const prefix = index === activeIndex ? bold(">") : dim("·");
    lines.push(truncateToWidth(`${prefix} ${matches[index]!.label}`, inner));
  }

  return lines;
}

function renderGlobalSkillsView(
  range: SkillRangeAgg,
  selectedDays: number,
  data: SkillBreakdownData,
  isLight: boolean,
  inner: number,
): string[] {
  const background = isLight ? LIGHT_BG : DEFAULT_BG;
  const emptyCell = isLight ? LIGHT_EMPTY_CELL_BG : EMPTY_CELL_BG;

  const lines: string[] = [];
  lines.push(truncateToWidth(rangeSummary(range, selectedDays), inner));
  lines.push("");

  const maxScale =
    range.days.length === 7 ? 4 : range.days.length === 30 ? 3 : 2;
  const weeks = weeksForRange(range);
  const leftMargin = 4;
  const gap = 1;
  const graphArea = Math.max(1, inner - leftMargin);
  const idealCellWidth =
    Math.floor((graphArea + gap) / Math.max(1, weeks)) - gap;
  const cellWidth = Math.min(maxScale, Math.max(1, idealCellWidth));

  const graphLines = renderGraphLines(
    range,
    data.palette.skillColors,
    data.palette.otherColor,
    { cellWidth, gap, bgColor: background, emptyCellBg: emptyCell },
  );

  const graphWidth = Math.max(
    0,
    ...graphLines.map((line) => visibleWidth(line)),
  );
  const legendItems = renderLegendItems(data, background);
  const legendTitle = dim("Top skills (30d palette):");
  const separator = 2;
  const legendWidth = inner - graphWidth - separator;
  const showSideLegend = legendWidth >= 18;

  if (showSideLegend) {
    const legendBlock = [legendTitle, ...legendItems];
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

    const padRightAnsi = (text: string, target: number): string => {
      const width = visibleWidth(text);
      return width >= target ? text : text + " ".repeat(target - width);
    };

    for (let index = 0; index < graphLines.length; index++) {
      const left = padRightAnsi(graphLines[index] ?? "", graphWidth);
      const right = truncateToWidth(
        legendLines[index] ?? "",
        Math.max(0, legendWidth),
      );
      lines.push(
        truncateToWidth(`${left}${" ".repeat(separator)}${right}`, inner),
      );
    }
  } else {
    for (const graphLine of graphLines)
      lines.push(truncateToWidth(graphLine, inner));
    lines.push("");
    lines.push(truncateToWidth(legendTitle, inner));
    for (const item of legendItems) lines.push(truncateToWidth(item, inner));
  }

  lines.push("");
  for (const tableLine of renderSkillTable(range)) {
    lines.push(truncateToWidth(tableLine, inner));
  }

  return lines;
}

function modelScopeTag(
  modelKey: ModelKey | null,
  selectedModel: ModelKey | null,
): string {
  const label = modelKey ?? ALL_MODELS_LABEL;
  return modelKey === selectedModel ? bold(`[${label}]`) : dim(` ${label} `);
}

function renderProjectTable(
  range: SkillRangeAgg,
  skillName: SkillName,
  selectedModel: ModelKey | null,
  maxRows = TOP_SKILLS_LIMIT,
): string[] {
  const rows = sortMapByValueDesc(
    getProjectCountsForSkill(range, skillName, selectedModel),
  ).slice(0, maxRows);
  const total = getSkillCount(range, skillName, selectedModel);
  const countWidth = 8;
  const displayProjects = rows.map((row) => abbreviateProjectPath(row.key, 38));
  const projectWidth = Math.min(
    40,
    Math.max(
      "project".length,
      ...displayProjects.map((project) => project.length),
    ),
  );

  const lines: string[] = [];
  lines.push(
    `${padRight("project", projectWidth)}  ${padLeft("count", countWidth)}  ${padLeft("share", 6)}`,
  );
  lines.push(
    `${"-".repeat(projectWidth)}  ${"-".repeat(countWidth)}  ${"-".repeat(6)}`,
  );

  for (let index = 0; index < rows.length; index++) {
    const row = rows[index]!;
    const displayProject = displayProjects[index] ?? row.key;
    lines.push(
      `${padRight(displayProject.slice(0, projectWidth), projectWidth)}  ${padLeft(formatCount(row.value), countWidth)}  ${padLeft(formatShare(row.value, total), 6)}`,
    );
  }

  if (rows.length === 0) {
    lines.push(dim("(no project data found)"));
  }

  return lines;
}

function renderProjectsView(
  range: SkillRangeAgg,
  inner: number,
  selectedSkill: SkillName | null,
  selectedModel: ModelKey | null,
): string[] {
  if (!selectedSkill) {
    return [
      dim("Use / to fuzzy-search a skill and jump to its project summary."),
    ];
  }

  const total = getSkillCount(range, selectedSkill, selectedModel);
  const orderedModels = getOrderedModelsForSkill(range, selectedSkill);
  const scope = selectedModel ?? ALL_MODELS_LABEL;
  const modelTabs = [modelScopeTag(null, selectedModel)]
    .concat(
      orderedModels.map((modelKey) => modelScopeTag(modelKey, selectedModel)),
    )
    .join(" ");

  const lines: string[] = [];
  lines.push(`skill: ${selectedSkill}`);
  lines.push(`scope: ${scope}`);
  lines.push(
    `invocations: ${formatCount(total)} (${formatShare(total, range.totalInvocations)} of all skill loads)`,
  );
  lines.push(truncateToWidth(`models: ${modelTabs}`, inner));
  lines.push("");

  for (const tableLine of renderProjectTable(
    range,
    selectedSkill,
    selectedModel,
  )) {
    lines.push(truncateToWidth(tableLine, inner));
  }

  return lines;
}

export function renderBreakdownBody(
  range: SkillRangeAgg,
  selectedDays: number,
  data: SkillBreakdownData,
  isLight: boolean,
  inner: number,
  rangeIndex: number,
  view: SkillBreakdownView,
  selectedSkill: SkillName | null,
  selectedModel: ModelKey | null,
  isSearchMode: boolean,
  searchQuery: string,
  selectedSearchIndex: number,
): string[] {
  const rangeTab = (days: number, index: number): string => {
    const label = `${days}d`;
    return index === rangeIndex ? bold(`[${label}]`) : dim(` ${label} `);
  };
  const viewTab = (candidate: SkillBreakdownView): string => {
    return candidate === view ? bold(`[${candidate}]`) : dim(` ${candidate} `);
  };

  const lines: string[] = [];
  const tabs = `${rangeTab(7, 0)} ${rangeTab(30, 1)} ${rangeTab(90, 2)}  ${viewTab("skills")} ${viewTab("projects")}`;
  lines.push(truncateToWidth(tabs, inner));

  if (isSearchMode) {
    lines.push("");
    for (const searchLine of renderSearchBlock(
      range,
      searchQuery,
      inner,
      selectedSearchIndex,
    )) {
      lines.push(truncateToWidth(searchLine, inner));
    }
    lines.push("");
  } else {
    lines.push("");
  }

  const bodyLines =
    view === "projects"
      ? renderProjectsView(range, inner, selectedSkill, selectedModel)
      : renderGlobalSkillsView(range, selectedDays, data, isLight, inner);

  for (const line of bodyLines) {
    lines.push(truncateToWidth(line, inner));
  }

  return lines;
}
