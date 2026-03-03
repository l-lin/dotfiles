import path from "node:path";
import type {
  ModelKey,
  ParsedSession,
  DayAgg,
  RangeAgg,
  RGB,
  BreakdownData,
  MeasurementMode,
  BreakdownProgressState,
} from "./types.ts";
import { RANGE_DAYS, SESSION_ROOT, PALETTE } from "./constants.ts";
import { weightedMix } from "./color-utils.ts";
import { toLocalDayKey, localMidnight, addDaysLocal } from "./date-utils.ts";
import { walkSessionFiles, parseSessionFile } from "./session-parser.ts";

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
}

export function sortMapByValueDesc<K extends string>(
  m: Map<K, number>,
): Array<{ key: K; value: number }> {
  return [...m.entries()]
    .map(([key, value]) => ({ key, value }))
    .sort((a, b) => b.value - a.value);
}

export function choosePaletteFromLast30Days(
  range30: RangeAgg,
  topN = 4,
): {
  modelColors: Map<ModelKey, RGB>;
  otherColor: RGB;
  orderedModels: ModelKey[];
} {
  // Prefer cost if any cost exists, else tokens, else messages, else sessions.
  const costSum = [...range30.modelCost.values()].reduce((a, b) => a + b, 0);
  const popularity =
    costSum > 0
      ? range30.modelCost
      : range30.totalTokens > 0
        ? range30.modelTokens
        : range30.totalMessages > 0
          ? range30.modelMessages
          : range30.modelSessions;

  const sorted = sortMapByValueDesc(popularity);
  const orderedModels = sorted.slice(0, topN).map((x) => x.key);
  const modelColors = new Map<ModelKey, RGB>();
  for (let i = 0; i < orderedModels.length; i++) {
    modelColors.set(orderedModels[i], PALETTE[i % PALETTE.length]);
  }
  return {
    modelColors,
    otherColor: { r: 160, g: 160, b: 160 },
    orderedModels,
  };
}

export function dayMixedColor(
  day: DayAgg,
  modelColors: Map<ModelKey, RGB>,
  otherColor: RGB,
  mode: MeasurementMode,
): RGB {
  const parts: Array<{ color: RGB; weight: number }> = [];
  let otherWeight = 0;

  let map: Map<ModelKey, number>;
  if (mode === "tokens") {
    map =
      day.tokens > 0
        ? day.tokensByModel
        : day.messages > 0
          ? day.messagesByModel
          : day.sessionsByModel;
  } else if (mode === "messages") {
    map = day.messages > 0 ? day.messagesByModel : day.sessionsByModel;
  } else {
    map = day.sessionsByModel;
  }

  for (const [mk, w] of map.entries()) {
    const c = modelColors.get(mk);
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
    const maxTokens = Math.max(0, ...range.days.map((d) => d.tokens));
    if (maxTokens > 0)
      return { kind: "tokens", max: maxTokens, denom: Math.log1p(maxTokens) };
    // fall back if tokens aren't available
    mode = "messages";
  }

  if (mode === "messages") {
    const maxMessages = Math.max(0, ...range.days.map((d) => d.messages));
    if (maxMessages > 0)
      return {
        kind: "messages",
        max: maxMessages,
        denom: Math.log1p(maxMessages),
      };
    // fall back if messages aren't available
    mode = "sessions";
  }

  const maxSessions = Math.max(0, ...range.days.map((d) => d.sessions));
  return { kind: "sessions", max: maxSessions, denom: Math.log1p(maxSessions) };
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
  return { generatedAt: now, ranges, palette };
}
