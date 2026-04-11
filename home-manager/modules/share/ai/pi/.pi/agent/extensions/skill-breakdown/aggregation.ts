import path from "node:path";
import {
  addDaysLocal,
  localMidnight,
  toLocalDayKey,
} from "../session-breakdown/date-utils.js";
import { formatCount } from "../session-breakdown/color-utils.js";
import {
  OTHER_COLOR,
  PALETTE,
  RANGE_DAYS,
  TOP_SKILLS_LIMIT,
  UNKNOWN_MODEL_LABEL,
  UNKNOWN_PROJECT_LABEL,
  getSessionRoot,
} from "./constants.js";
import { loadGlobalUserSkillNames } from "./global-skills.js";
import {
  parseSkillSessionFile,
  walkRecentSessionFiles,
} from "./session-parser.js";
import type {
  ModelKey,
  ProjectKey,
  RGB,
  SkillBreakdownData,
  SkillBreakdownProgressState,
  SkillDayAgg,
  SkillName,
  SkillRangeAgg,
} from "./types.js";

function incrementCount<K extends string>(
  counts: Map<K, number>,
  key: K,
  amount = 1,
): void {
  counts.set(key, (counts.get(key) ?? 0) + amount);
}

function getOrCreateNestedMap<K1 extends string, K2 extends string, V>(
  maps: Map<K1, Map<K2, V>>,
  key: K1,
): Map<K2, V> {
  let inner = maps.get(key);
  if (!inner) {
    inner = new Map<K2, V>();
    maps.set(key, inner);
  }
  return inner;
}

function normalizeProjectKey(project: ProjectKey | null): ProjectKey {
  return typeof project === "string" && project.trim()
    ? project.trim()
    : UNKNOWN_PROJECT_LABEL;
}

function normalizeModelKey(model: ModelKey | null): ModelKey {
  return typeof model === "string" && model.trim()
    ? model.trim()
    : UNKNOWN_MODEL_LABEL;
}

export function buildRangeAgg(days: number, now: Date): SkillRangeAgg {
  const end = localMidnight(now);
  const start = addDaysLocal(end, -(days - 1));
  const outDays: SkillDayAgg[] = [];
  const dayByKey = new Map<string, SkillDayAgg>();

  for (let index = 0; index < days; index++) {
    const date = addDaysLocal(start, index);
    const dayKeyLocal = toLocalDayKey(date);
    const day: SkillDayAgg = {
      date,
      dayKeyLocal,
      invocations: 0,
      skillCounts: new Map(),
    };

    outDays.push(day);
    dayByKey.set(dayKeyLocal, day);
  }

  return {
    days: outDays,
    dayByKey,
    totalInvocations: 0,
    sessionCount: 0,
    skillCounts: new Map(),
    projectCountsBySkill: new Map(),
    modelCountsBySkill: new Map(),
    projectModelCountsBySkill: new Map(),
  };
}

export function addSkillToRange(
  range: SkillRangeAgg,
  skillName: SkillName,
  timestamp: Date,
  project: ProjectKey | null,
  model: ModelKey | null,
): void {
  const day = range.dayByKey.get(toLocalDayKey(timestamp));
  if (!day) return;

  const projectKey = normalizeProjectKey(project);
  const modelKey = normalizeModelKey(model);

  day.invocations += 1;
  incrementCount(day.skillCounts, skillName);

  range.totalInvocations += 1;
  incrementCount(range.skillCounts, skillName);

  const projectCounts = getOrCreateNestedMap(
    range.projectCountsBySkill,
    skillName,
  );
  incrementCount(projectCounts, projectKey);

  const modelCounts = getOrCreateNestedMap(range.modelCountsBySkill, skillName);
  incrementCount(modelCounts, modelKey);

  const projectModelCounts = getOrCreateNestedMap(
    range.projectModelCountsBySkill,
    skillName,
  );
  let modelCountsByProject = projectModelCounts.get(projectKey);
  if (!modelCountsByProject) {
    modelCountsByProject = new Map<ModelKey, number>();
    projectModelCounts.set(projectKey, modelCountsByProject);
  }
  incrementCount(modelCountsByProject, modelKey);
}

export function sortMapByValueDesc<K extends string>(
  values: Map<K, number>,
): Array<{ key: K; value: number }> {
  return [...values.entries()]
    .map(([key, value]) => ({ key, value }))
    .sort((left, right) => {
      if (right.value !== left.value) return right.value - left.value;
      return left.key.localeCompare(right.key);
    });
}

export function sortMapByValueAsc<K extends string>(
  values: Map<K, number>,
): Array<{ key: K; value: number }> {
  return [...values.entries()]
    .map(([key, value]) => ({ key, value }))
    .sort((left, right) => {
      if (left.value !== right.value) return left.value - right.value;
      return left.key.localeCompare(right.key);
    });
}

export function choosePaletteFromLast30Days(
  range30: SkillRangeAgg,
  topN = TOP_SKILLS_LIMIT,
): {
  skillColors: Map<SkillName, RGB>;
  orderedSkills: SkillName[];
  otherColor: RGB;
} {
  const orderedSkills = sortMapByValueDesc(range30.skillCounts)
    .slice(0, topN)
    .map((entry) => entry.key);

  const skillColors = new Map<SkillName, RGB>(
    orderedSkills.map((skillName, index) => [
      skillName,
      PALETTE[index % PALETTE.length],
    ]),
  );

  return {
    skillColors,
    orderedSkills,
    otherColor: OTHER_COLOR,
  };
}

export async function computeSkillBreakdown(options?: {
  root?: string;
  now?: Date;
  signal?: AbortSignal;
  onProgress?: (update: Partial<SkillBreakdownProgressState>) => void;
  globalUserSkillRoot?: string | null;
}): Promise<SkillBreakdownData> {
  const now = options?.now ?? new Date();
  const root = options?.root ?? getSessionRoot();
  const signal = options?.signal;
  const onProgress = options?.onProgress;
  const globalUserSkillNames = loadGlobalUserSkillNames(
    options?.globalUserSkillRoot,
  );

  const ranges = new Map<number, SkillRangeAgg>();
  const sessionsPerRange = new Map<number, Set<string>>();
  for (const days of RANGE_DAYS) {
    ranges.set(days, buildRangeAgg(days, now));
    sessionsPerRange.set(days, new Set());
  }

  const range90 = ranges.get(90)!;
  const start90 = range90.days[0]?.date ?? localMidnight(now);

  onProgress?.({
    phase: "scan",
    foundFiles: 0,
    parsedFiles: 0,
    totalFiles: 0,
    currentFile: undefined,
  });

  const candidates = await walkRecentSessionFiles(
    root,
    start90,
    signal,
    (found) => {
      onProgress?.({ phase: "scan", foundFiles: found });
    },
  );

  onProgress?.({
    phase: "parse",
    foundFiles: candidates.length,
    parsedFiles: 0,
    totalFiles: candidates.length,
    currentFile: candidates[0] ? path.basename(candidates[0]) : undefined,
  });

  let parsedFiles = 0;
  for (const filePath of candidates) {
    if (signal?.aborted) break;

    parsedFiles += 1;
    onProgress?.({
      phase: "parse",
      foundFiles: candidates.length,
      parsedFiles,
      totalFiles: candidates.length,
      currentFile: path.basename(filePath),
    });

    const parsedSession = await parseSkillSessionFile(filePath, signal);
    if (!parsedSession) continue;

    for (const [skillName, firstLoadedAt] of parsedSession.skillFirstLoadedAt) {
      const skillDay = localMidnight(firstLoadedAt);
      const project = parsedSession.skillProjectByName.get(skillName) ?? null;
      const model = parsedSession.skillModelByName.get(skillName) ?? null;

      for (const days of RANGE_DAYS) {
        const range = ranges.get(days)!;
        const rangeStart = range.days[0]?.date;
        const rangeEnd = range.days[range.days.length - 1]?.date;
        if (!rangeStart || !rangeEnd) continue;
        if (skillDay < rangeStart || skillDay > rangeEnd) continue;

        addSkillToRange(range, skillName, firstLoadedAt, project, model);
        sessionsPerRange.get(days)?.add(parsedSession.filePath);
      }
    }
  }

  onProgress?.({ phase: "finalize", currentFile: undefined });

  for (const days of RANGE_DAYS) {
    const range = ranges.get(days)!;
    range.sessionCount = sessionsPerRange.get(days)?.size ?? 0;
  }

  return {
    generatedAt: now,
    ranges,
    globalUserSkillNames,
    palette: choosePaletteFromLast30Days(ranges.get(30)!, TOP_SKILLS_LIMIT),
  };
}

export function getSkillCount(
  range: SkillRangeAgg,
  skillName: SkillName,
  modelKey: ModelKey | null = null,
): number {
  if (!modelKey) return range.skillCounts.get(skillName) ?? 0;
  return range.modelCountsBySkill.get(skillName)?.get(modelKey) ?? 0;
}

export function getProjectCountsForSkill(
  range: SkillRangeAgg,
  skillName: SkillName,
  modelKey: ModelKey | null = null,
): Map<ProjectKey, number> {
  if (!modelKey) {
    return new Map(range.projectCountsBySkill.get(skillName) ?? []);
  }

  const scopedProjectCounts = new Map<ProjectKey, number>();
  const projectModelCounts = range.projectModelCountsBySkill.get(skillName);
  if (!projectModelCounts) return scopedProjectCounts;

  for (const [projectKey, modelCounts] of projectModelCounts.entries()) {
    const count = modelCounts.get(modelKey) ?? 0;
    if (count > 0) scopedProjectCounts.set(projectKey, count);
  }

  return scopedProjectCounts;
}

export function getOrderedModelsForSkill(
  range: SkillRangeAgg,
  skillName: SkillName,
): ModelKey[] {
  return sortMapByValueDesc(
    range.modelCountsBySkill.get(skillName) ?? new Map(),
  ).map((entry) => entry.key);
}

export function formatShare(value: number, total: number): string {
  if (total <= 0) return "0%";
  return `${Math.round((value / total) * 100)}%`;
}

export function rangeSummary(range: SkillRangeAgg, days: number): string {
  return `Last ${days} days: ${formatCount(range.totalInvocations)} invocations across ${formatCount(range.sessionCount)} sessions · ${formatCount(range.skillCounts.size)} skills`;
}

export function renderTopSkillsText(
  range: SkillRangeAgg,
  maxRows = TOP_SKILLS_LIMIT,
): string[] {
  const rows = sortMapByValueDesc(range.skillCounts).slice(0, maxRows);
  if (rows.length === 0) return [];

  return [
    "",
    "Top skills:",
    ...rows.map(
      (row, index) =>
        `${index + 1}. ${row.key} ${formatCount(row.value)} (${formatShare(row.value, range.totalInvocations)})`,
    ),
  ];
}
