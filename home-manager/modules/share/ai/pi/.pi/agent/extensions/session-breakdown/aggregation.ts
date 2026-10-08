import path from "node:path";
import type {
  ModelKey,
  CwdKey,
  DowKey,
  TodKey,
  BreakdownView,
  ParsedSession,
  DayAgg,
  RangeAgg,
  RGB,
  BreakdownData,
  MeasurementMode,
  BreakdownProgressState,
} from "./types.js";
import {
  RANGE_DAYS,
  SESSION_ROOT,
  PALETTE,
  DOW_NAMES,
  DOW_PALETTE,
  TOD_BUCKETS,
  TOD_PALETTE,
} from "./constants.js";
import { weightedMix } from "./color-utils.js";
import {
  toLocalDayKey,
  localMidnight,
  addDaysLocal,
  mondayIndex,
} from "./date-utils.js";
import {
  walkSessionFiles,
  parseSessionFile,
  todBucketForHour,
} from "./session-parser.js";

export function buildRangeAgg(days: number, now: Date): RangeAgg {
  const end = localMidnight(now);
  const start = addDaysLocal(end, -(days - 1));
  const outDays: DayAgg[] = [];
  const dayByKey = new Map<string, DayAgg>();

  for (let i = 0; i < days; i++) {
    const d = addDaysLocal(start, i);
    const dayKeyLocal = toLocalDayKey(d);
    const day: DayAgg = {
      date: d,
      dayKeyLocal,
      sessions: 0,
      messages: 0,
      tokens: 0,
      totalCost: 0,
      costByModel: new Map(),
      sessionsByModel: new Map(),
      messagesByModel: new Map(),
      tokensByModel: new Map(),
      sessionsByCwd: new Map(),
      messagesByCwd: new Map(),
      tokensByCwd: new Map(),
      costByCwd: new Map(),
      sessionsByTod: new Map(),
      messagesByTod: new Map(),
      tokensByTod: new Map(),
      costByTod: new Map(),
    };
    outDays.push(day);
    dayByKey.set(dayKeyLocal, day);
  }

  return {
    days: outDays,
    dayByKey,
    sessions: 0,
    totalMessages: 0,
    totalTokens: 0,
    totalCost: 0,
    modelCost: new Map(),
    modelSessions: new Map(),
    modelMessages: new Map(),
    modelTokens: new Map(),
    cwdCost: new Map(),
    cwdSessions: new Map(),
    cwdMessages: new Map(),
    cwdTokens: new Map(),
    dowCost: new Map(),
    dowSessions: new Map(),
    dowMessages: new Map(),
    dowTokens: new Map(),
    todCost: new Map(),
    todSessions: new Map(),
    todMessages: new Map(),
    todTokens: new Map(),
  };
}

function incrementMap<K>(map: Map<K, number>, key: K, amount = 1): void {
  map.set(key, (map.get(key) ?? 0) + amount);
}

export function addSessionToRange(
  range: RangeAgg,
  session: ParsedSession,
): void {
  const activeDays = new Set<DayAgg>();
  const models = new Set<ModelKey>();
  const dows = new Set<DowKey>();
  const tods = new Set<TodKey>();
  const dayModels = new Map<DayAgg, Set<ModelKey>>();
  const dayTods = new Map<DayAgg, Set<TodKey>>();
  // Empty sessions still count on their creation day.
  const activities =
    session.activities.length > 0
      ? session.activities
      : [
          {
            timestamp: session.startedAt,
            model: "unknown",
            messages: 0,
            tokens: 0,
            cost: 0,
          },
        ];

  for (const activity of activities) {
    const day = range.dayByKey.get(toLocalDayKey(activity.timestamp));
    if (!day) continue;
    const dow = DOW_NAMES[mondayIndex(activity.timestamp)];
    const tod = todBucketForHour(activity.timestamp.getHours());
    const model = activity.model;
    activeDays.add(day);
    models.add(model);
    dows.add(dow);
    tods.add(tod);
    if (!dayModels.has(day)) dayModels.set(day, new Set());
    if (!dayTods.has(day)) dayTods.set(day, new Set());
    dayModels.get(day)!.add(model);
    dayTods.get(day)!.add(tod);

    range.totalMessages += activity.messages;
    range.totalTokens += activity.tokens;
    range.totalCost += activity.cost;
    day.messages += activity.messages;
    day.tokens += activity.tokens;
    day.totalCost += activity.cost;

    incrementMap(day.messagesByModel, model, activity.messages);
    incrementMap(range.modelMessages, model, activity.messages);
    incrementMap(day.tokensByModel, model, activity.tokens);
    incrementMap(range.modelTokens, model, activity.tokens);
    incrementMap(day.costByModel, model, activity.cost);
    incrementMap(range.modelCost, model, activity.cost);

    if (session.cwd) {
      incrementMap(day.messagesByCwd, session.cwd, activity.messages);
      incrementMap(range.cwdMessages, session.cwd, activity.messages);
      incrementMap(day.tokensByCwd, session.cwd, activity.tokens);
      incrementMap(range.cwdTokens, session.cwd, activity.tokens);
      incrementMap(day.costByCwd, session.cwd, activity.cost);
      incrementMap(range.cwdCost, session.cwd, activity.cost);
    }

    incrementMap(range.dowMessages, dow, activity.messages);
    incrementMap(range.dowTokens, dow, activity.tokens);
    incrementMap(range.dowCost, dow, activity.cost);
    incrementMap(day.messagesByTod, tod, activity.messages);
    incrementMap(range.todMessages, tod, activity.messages);
    incrementMap(day.tokensByTod, tod, activity.tokens);
    incrementMap(range.todTokens, tod, activity.tokens);
    incrementMap(day.costByTod, tod, activity.cost);
    incrementMap(range.todCost, tod, activity.cost);
  }

  if (activeDays.size === 0) return;
  // Count a session once per range, but once on each day/bucket where it was active.
  range.sessions += 1;
  for (const model of models) incrementMap(range.modelSessions, model);
  for (const dow of dows) incrementMap(range.dowSessions, dow);
  for (const tod of tods) incrementMap(range.todSessions, tod);
  if (session.cwd) incrementMap(range.cwdSessions, session.cwd);
  for (const day of activeDays) {
    day.sessions += 1;
    for (const model of dayModels.get(day)!)
      incrementMap(day.sessionsByModel, model);
    for (const tod of dayTods.get(day)!) incrementMap(day.sessionsByTod, tod);
    if (session.cwd) incrementMap(day.sessionsByCwd, session.cwd);
  }
}

export function sortMapByValueDesc<K extends string>(
  m: Map<K, number>,
): Array<{ key: K; value: number }> {
  return [...m.entries()]
    .map(([key, value]) => ({ key, value }))
    .sort((a, b) => b.value - a.value);
}

// Prefer cost > tokens > messages > sessions for palette ordering.
function pickPopularityMap(
  range: RangeAgg,
  costMap: Map<string, number>,
  tokenMap: Map<string, number>,
  messageMap: Map<string, number>,
  sessionMap: Map<string, number>,
): Map<string, number> {
  const costSum = [...costMap.values()].reduce((a, b) => a + b, 0);
  if (costSum > 0) return costMap;
  if (range.totalTokens > 0) return tokenMap;
  if (range.totalMessages > 0) return messageMap;
  return sessionMap;
}

export function choosePaletteFromLast30Days(
  range30: RangeAgg,
  topN = 4,
): {
  modelColors: Map<ModelKey, RGB>;
  otherColor: RGB;
  orderedModels: ModelKey[];
} {
  const popularity = pickPopularityMap(
    range30,
    range30.modelCost,
    range30.modelTokens,
    range30.modelMessages,
    range30.modelSessions,
  );
  const orderedModels = sortMapByValueDesc(popularity)
    .slice(0, topN)
    .map((x) => x.key);
  const modelColors = new Map<ModelKey, RGB>(
    orderedModels.map((mk, i) => [mk, PALETTE[i % PALETTE.length]]),
  );
  return { modelColors, otherColor: { r: 160, g: 160, b: 160 }, orderedModels };
}

export function chooseCwdPaletteFromLast30Days(
  range30: RangeAgg,
  topN = 4,
): {
  cwdColors: Map<CwdKey, RGB>;
  otherColor: RGB;
  orderedCwds: CwdKey[];
} {
  const popularity = pickPopularityMap(
    range30,
    range30.cwdCost,
    range30.cwdTokens,
    range30.cwdMessages,
    range30.cwdSessions,
  );
  const orderedCwds = sortMapByValueDesc(popularity)
    .slice(0, topN)
    .map((x) => x.key);
  const cwdColors = new Map<CwdKey, RGB>(
    orderedCwds.map((cwd, i) => [cwd, PALETTE[i % PALETTE.length]]),
  );
  return { cwdColors, otherColor: { r: 160, g: 160, b: 160 }, orderedCwds };
}

export function buildDowPalette(): {
  dowColors: Map<DowKey, RGB>;
  orderedDows: DowKey[];
} {
  const dowColors = new Map<DowKey, RGB>();
  for (let i = 0; i < DOW_NAMES.length; i++) {
    dowColors.set(DOW_NAMES[i], DOW_PALETTE[i]);
  }
  return { dowColors, orderedDows: [...DOW_NAMES] };
}

export function buildTodPalette(): {
  todColors: Map<TodKey, RGB>;
  orderedTods: TodKey[];
} {
  const todColors = new Map<TodKey, RGB>();
  const orderedTods: TodKey[] = [];
  for (const b of TOD_BUCKETS) {
    const c = TOD_PALETTE.get(b.key);
    if (c) todColors.set(b.key, c);
    orderedTods.push(b.key);
  }
  return { todColors, orderedTods };
}

function selectDayMap(
  day: DayAgg,
  mode: MeasurementMode,
  byTokens: Map<string, number>,
  byMessages: Map<string, number>,
  bySessions: Map<string, number>,
): Map<string, number> {
  if (mode === "tokens" && day.tokens > 0) return byTokens;
  if (mode !== "sessions" && day.messages > 0) return byMessages;
  return bySessions;
}

export function dayMixedColor(
  day: DayAgg,
  colorMap: Map<string, RGB>,
  otherColor: RGB,
  mode: MeasurementMode,
  view: BreakdownView = "model",
): RGB {
  // dow: each day IS a single dow – return its color directly
  if (view === "dow") {
    const dowKey = DOW_NAMES[mondayIndex(day.date)];
    return colorMap.get(dowKey) ?? otherColor;
  }

  let map: Map<string, number>;
  if (view === "tod") {
    map = selectDayMap(
      day,
      mode,
      day.tokensByTod,
      day.messagesByTod,
      day.sessionsByTod,
    );
  } else if (view === "cwd") {
    map = selectDayMap(
      day,
      mode,
      day.tokensByCwd,
      day.messagesByCwd,
      day.sessionsByCwd,
    );
  } else {
    map = selectDayMap(
      day,
      mode,
      day.tokensByModel,
      day.messagesByModel,
      day.sessionsByModel,
    );
  }

  const parts: Array<{ color: RGB; weight: number }> = [];
  let otherWeight = 0;
  for (const [key, w] of map.entries()) {
    const c = colorMap.get(key);
    if (c) parts.push({ color: c, weight: w });
    else otherWeight += w;
  }
  if (otherWeight > 0) parts.push({ color: otherColor, weight: otherWeight });
  return weightedMix(parts);
}

export function graphMetricForRange(
  range: RangeAgg,
  mode: MeasurementMode,
): { kind: "sessions" | "messages" | "tokens"; max: number; denom: number } {
  if (mode === "tokens") {
    const max = Math.max(0, ...range.days.map((d) => d.tokens));
    if (max > 0) return { kind: "tokens", max, denom: Math.log1p(max) };
  }
  if (mode === "tokens" || mode === "messages") {
    const max = Math.max(0, ...range.days.map((d) => d.messages));
    if (max > 0) return { kind: "messages", max, denom: Math.log1p(max) };
  }
  const max = Math.max(0, ...range.days.map((d) => d.sessions));
  return { kind: "sessions", max, denom: Math.log1p(max) };
}

export async function computeBreakdown(
  signal?: AbortSignal,
  onProgress?: (update: Partial<BreakdownProgressState>) => void,
): Promise<BreakdownData> {
  const now = new Date();
  const ranges = new Map<number, RangeAgg>();
  for (const d of RANGE_DAYS) ranges.set(d, buildRangeAgg(d, now));
  const range90 = ranges.get(90)!;
  const start90 = range90.days[0].date;

  onProgress?.({
    phase: "scan",
    foundFiles: 0,
    parsedFiles: 0,
    totalFiles: 0,
    currentFile: undefined,
  });

  const candidates = await walkSessionFiles(
    SESSION_ROOT,
    start90,
    signal,
    (found) => {
      onProgress?.({ phase: "scan", foundFiles: found });
    },
  );

  const totalFiles = candidates.length;
  onProgress?.({
    phase: "parse",
    foundFiles: totalFiles,
    totalFiles,
    parsedFiles: 0,
    currentFile: totalFiles > 0 ? path.basename(candidates[0]!) : undefined,
  });

  let parsedFiles = 0;
  for (const filePath of candidates) {
    if (signal?.aborted) break;
    parsedFiles += 1;
    onProgress?.({
      phase: "parse",
      parsedFiles,
      totalFiles,
      currentFile: path.basename(filePath),
    });

    const session = await parseSessionFile(filePath, signal);
    if (!session) continue;

    for (const d of RANGE_DAYS) {
      addSessionToRange(ranges.get(d)!, session);
    }
  }

  onProgress?.({ phase: "finalize", currentFile: undefined });

  const palette = choosePaletteFromLast30Days(ranges.get(30)!, 4);
  const cwdPalette = chooseCwdPaletteFromLast30Days(ranges.get(30)!, 4);
  const dowPalette = buildDowPalette();
  const todPalette = buildTodPalette();

  return {
    generatedAt: now,
    ranges,
    palette,
    cwdPalette,
    dowPalette,
    todPalette,
  };
}
