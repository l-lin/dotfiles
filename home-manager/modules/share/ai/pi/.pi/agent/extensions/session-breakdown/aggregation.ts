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
import { walkSessionFiles, parseSessionFile } from "./session-parser.js";

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

export function addSessionToRange(
  range: RangeAgg,
  session: ParsedSession,
): void {
  const day = range.dayByKey.get(session.dayKeyLocal);
  if (!day) return;

  range.sessions += 1;
  range.totalMessages += session.messages;
  range.totalTokens += session.tokens;
  range.totalCost += session.totalCost;
  day.sessions += 1;
  day.messages += session.messages;
  day.tokens += session.tokens;
  day.totalCost += session.totalCost;

  // Sessions-per-model (presence)
  for (const mk of session.modelsUsed) {
    day.sessionsByModel.set(mk, (day.sessionsByModel.get(mk) ?? 0) + 1);
    range.modelSessions.set(mk, (range.modelSessions.get(mk) ?? 0) + 1);
  }

  // Messages-per-model
  for (const [mk, n] of session.messagesByModel.entries()) {
    day.messagesByModel.set(mk, (day.messagesByModel.get(mk) ?? 0) + n);
    range.modelMessages.set(mk, (range.modelMessages.get(mk) ?? 0) + n);
  }

  // Tokens-per-model
  for (const [mk, n] of session.tokensByModel.entries()) {
    day.tokensByModel.set(mk, (day.tokensByModel.get(mk) ?? 0) + n);
    range.modelTokens.set(mk, (range.modelTokens.get(mk) ?? 0) + n);
  }

  // Cost-per-model
  for (const [mk, cost] of session.costByModel.entries()) {
    day.costByModel.set(mk, (day.costByModel.get(mk) ?? 0) + cost);
    range.modelCost.set(mk, (range.modelCost.get(mk) ?? 0) + cost);
  }

  // CWD aggregation
  const cwd = session.cwd;
  if (cwd) {
    day.sessionsByCwd.set(cwd, (day.sessionsByCwd.get(cwd) ?? 0) + 1);
    range.cwdSessions.set(cwd, (range.cwdSessions.get(cwd) ?? 0) + 1);
    day.messagesByCwd.set(
      cwd,
      (day.messagesByCwd.get(cwd) ?? 0) + session.messages,
    );
    range.cwdMessages.set(
      cwd,
      (range.cwdMessages.get(cwd) ?? 0) + session.messages,
    );
    day.tokensByCwd.set(cwd, (day.tokensByCwd.get(cwd) ?? 0) + session.tokens);
    range.cwdTokens.set(cwd, (range.cwdTokens.get(cwd) ?? 0) + session.tokens);
    day.costByCwd.set(cwd, (day.costByCwd.get(cwd) ?? 0) + session.totalCost);
    range.cwdCost.set(cwd, (range.cwdCost.get(cwd) ?? 0) + session.totalCost);
  }

  // Day-of-week aggregation
  const dow = session.dow;
  range.dowSessions.set(dow, (range.dowSessions.get(dow) ?? 0) + 1);
  range.dowMessages.set(
    dow,
    (range.dowMessages.get(dow) ?? 0) + session.messages,
  );
  range.dowTokens.set(dow, (range.dowTokens.get(dow) ?? 0) + session.tokens);
  range.dowCost.set(dow, (range.dowCost.get(dow) ?? 0) + session.totalCost);

  // Time-of-day aggregation
  const tod = session.tod;
  day.sessionsByTod.set(tod, (day.sessionsByTod.get(tod) ?? 0) + 1);
  day.messagesByTod.set(
    tod,
    (day.messagesByTod.get(tod) ?? 0) + session.messages,
  );
  day.tokensByTod.set(tod, (day.tokensByTod.get(tod) ?? 0) + session.tokens);
  day.costByTod.set(tod, (day.costByTod.get(tod) ?? 0) + session.totalCost);
  range.todSessions.set(tod, (range.todSessions.get(tod) ?? 0) + 1);
  range.todMessages.set(
    tod,
    (range.todMessages.get(tod) ?? 0) + session.messages,
  );
  range.todTokens.set(tod, (range.todTokens.get(tod) ?? 0) + session.tokens);
  range.todCost.set(tod, (range.todCost.get(tod) ?? 0) + session.totalCost);
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

    const sessionDay = localMidnight(session.startedAt);
    for (const d of RANGE_DAYS) {
      const range = ranges.get(d)!;
      const start = range.days[0].date;
      const end = range.days[range.days.length - 1].date;
      if (sessionDay < start || sessionDay > end) continue;
      addSessionToRange(range, session);
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
