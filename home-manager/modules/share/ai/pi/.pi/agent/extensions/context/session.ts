import type {
  ExtensionCommandContext,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import type { SkillLoadedEntryData, SkillIndexEntry } from "./types.js";
import { SKILL_LOADED_ENTRY } from "./types.js";

type CustomEntry = {
  type: string;
  customType: string;
  data: SkillLoadedEntryData;
};

function isCustomEntry(entry: unknown): entry is CustomEntry {
  const e = entry as any;
  return e?.type === "custom" && typeof e?.customType === "string";
}

export function getLoadedSkillsFromSession(ctx: ExtensionContext): Set<string> {
  const loadedSkills = new Set<string>();

  for (const entry of ctx.sessionManager.getEntries()) {
    if (!isCustomEntry(entry)) continue;
    if (entry.customType !== SKILL_LOADED_ENTRY) continue;
    if (entry.data?.name) {
      loadedSkills.add(entry.data.name);
    }
  }

  return loadedSkills;
}

export function matchSkillForPath(
  absPath: string,
  skillIndex: SkillIndexEntry[],
): string | null {
  let best: SkillIndexEntry | null = null;
  for (const s of skillIndex) {
    if (!s.skillDir) continue;
    if (
      absPath === s.skillFilePath ||
      absPath.startsWith(s.skillDir + require("node:path").sep)
    ) {
      if (!best || s.skillDir.length > best.skillDir.length) best = s;
    }
  }
  return best?.name ?? null;
}

function extractCostTotal(usage: any): number {
  if (!usage?.cost) return 0;

  const cost = usage.cost;

  // Direct cost value
  if (typeof cost === "number") {
    return Number.isFinite(cost) ? cost : 0;
  }
  if (typeof cost === "string") {
    const parsed = Number(cost);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  // Nested cost.total
  const total = cost.total;
  if (typeof total === "number") {
    return Number.isFinite(total) ? total : 0;
  }
  if (typeof total === "string") {
    const parsed = Number(total);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  return 0;
}

type MessageEntry = {
  type: string;
  message: {
    role: string;
    usage?: {
      inputTokens?: number;
      outputTokens?: number;
      cacheRead?: number;
      cacheWrite?: number;
      cost?: any;
    };
  };
};

function isMessageEntry(entry: unknown): entry is MessageEntry {
  const e = entry as any;
  return e?.type === "message" && e?.message;
}

export function sumSessionUsage(ctx: ExtensionCommandContext): {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  totalTokens: number;
  totalCost: number;
} {
  let input = 0;
  let output = 0;
  let cacheRead = 0;
  let cacheWrite = 0;
  let totalCost = 0;

  for (const entry of ctx.sessionManager.getEntries()) {
    if (!isMessageEntry(entry)) continue;
    if (entry.message.role !== "assistant") continue;

    const usage = entry.message.usage;
    if (!usage) continue;

    input += Number(usage.inputTokens ?? 0) || 0;
    output += Number(usage.outputTokens ?? 0) || 0;
    cacheRead += Number(usage.cacheRead ?? 0) || 0;
    cacheWrite += Number(usage.cacheWrite ?? 0) || 0;
    totalCost += extractCostTotal(usage);
  }

  return {
    input,
    output,
    cacheRead,
    cacheWrite,
    totalTokens: input + output + cacheRead + cacheWrite,
    totalCost,
  };
}
