import path from "node:path";
import fs from "node:fs/promises";
import { createReadStream, type Dirent } from "node:fs";
import readline from "node:readline";
import type { ModelKey, TodKey, ParsedSession } from "./types.js";
import { DOW_NAMES, TOD_BUCKETS } from "./constants.js";
import { toLocalDayKey, localMidnight, mondayIndex } from "./date-utils.js";

export function todBucketForHour(hour: number): TodKey {
  for (const b of TOD_BUCKETS) {
    if (hour >= b.from && hour <= b.to) return b.key;
  }
  return "after-midnight";
}

export function modelKeyFromParts(
  provider?: unknown,
  model?: unknown,
): ModelKey | null {
  const p = typeof provider === "string" ? provider.trim() : "";
  const m = typeof model === "string" ? model.trim() : "";
  if (!p && !m) return null;
  if (!p) return m;
  if (!m) return p;
  return `${p}/${m}`;
}

export function parseSessionStartFromFilename(name: string): Date | null {
  // Example: 2026-02-02T21-52-28-774Z_<uuid>.jsonl
  const match = name.match(
    /^(\d{4}-\d{2}-\d{2})T(\d{2})-(\d{2})-(\d{2})-(\d{3})Z_/,
  );
  if (!match) return null;
  const iso = `${match[1]}T${match[2]}:${match[3]}:${match[4]}.${match[5]}Z`;
  const d = new Date(iso);
  return Number.isFinite(d.getTime()) ? d : null;
}

function extractProviderModelAndUsage(obj: any): {
  provider?: any;
  model?: any;
  modelId?: any;
  usage?: any;
} {
  // Session format varies across versions.
  // - Newer: { provider, model, usage } on the message wrapper
  // - Older: { message: { provider, model, usage } }
  const msg = obj?.message;
  return {
    provider: obj?.provider ?? msg?.provider,
    model: obj?.model ?? msg?.model,
    modelId: obj?.modelId ?? msg?.modelId,
    usage: obj?.usage ?? msg?.usage,
  };
}

function extractCostTotal(usage: any): number {
  if (!usage) return 0;
  const c = usage?.cost;
  if (typeof c === "number") return Number.isFinite(c) ? c : 0;
  if (typeof c === "string") {
    const n = Number(c);
    return Number.isFinite(n) ? n : 0;
  }
  const t = c?.total;
  if (typeof t === "number") return Number.isFinite(t) ? t : 0;
  if (typeof t === "string") {
    const n = Number(t);
    return Number.isFinite(n) ? n : 0;
  }
  return 0;
}

function extractTokensTotal(usage: any): number {
  // Usage format varies across providers and pi versions.
  // We try a few common shapes:
  // - { totalTokens }
  // - { total_tokens }
  // - { promptTokens, completionTokens }
  // - { prompt_tokens, completion_tokens }
  // - { input_tokens, output_tokens }
  // - { inputTokens, outputTokens }
  // - { tokens: number | { total } }
  if (!usage) return 0;

  const readNum = (v: any): number => {
    if (typeof v === "number") return Number.isFinite(v) ? v : 0;
    if (typeof v === "string") {
      const n = Number(v);
      return Number.isFinite(n) ? n : 0;
    }
    return 0;
  };

  let total = 0;
  // direct totals
  total =
    readNum(usage?.totalTokens) ||
    readNum(usage?.total_tokens) ||
    readNum(usage?.tokens) ||
    readNum(usage?.tokenCount) ||
    readNum(usage?.token_count);
  if (total > 0) return total;

  // nested tokens object
  total =
    readNum(usage?.tokens?.total) ||
    readNum(usage?.tokens?.totalTokens) ||
    readNum(usage?.tokens?.total_tokens);
  if (total > 0) return total;

  // sum of parts
  const a =
    readNum(usage?.promptTokens) ||
    readNum(usage?.prompt_tokens) ||
    readNum(usage?.inputTokens) ||
    readNum(usage?.input_tokens);
  const b =
    readNum(usage?.completionTokens) ||
    readNum(usage?.completion_tokens) ||
    readNum(usage?.outputTokens) ||
    readNum(usage?.output_tokens);
  const sum = a + b;
  return sum > 0 ? sum : 0;
}

export async function walkSessionFiles(
  root: string,
  startCutoffLocal: Date,
  signal?: AbortSignal,
  onFound?: (found: number) => void,
): Promise<string[]> {
  const out: string[] = [];
  const stack: string[] = [root];
  while (stack.length) {
    if (signal?.aborted) break;
    const dir = stack.pop()!;
    let entries: Dirent[] = [];
    try {
      entries = await fs.readdir(dir, { withFileTypes: true });
    } catch {
      continue;
    }

    for (const ent of entries) {
      if (signal?.aborted) break;
      const p = path.join(dir, ent.name);
      if (ent.isDirectory()) {
        stack.push(p);
        continue;
      }
      if (!ent.isFile() || !ent.name.endsWith(".jsonl")) continue;

      // Prefer filename timestamp, else fall back to mtime.
      const startedAt = parseSessionStartFromFilename(ent.name);
      if (startedAt) {
        if (localMidnight(startedAt) >= startCutoffLocal) {
          out.push(p);
          if (onFound && out.length % 10 === 0) onFound(out.length);
        }
        continue;
      }

      try {
        const st = await fs.stat(p);
        const approx = new Date(st.mtimeMs);
        if (localMidnight(approx) >= startCutoffLocal) {
          out.push(p);
          if (onFound && out.length % 10 === 0) onFound(out.length);
        }
      } catch {
        // ignore
      }
    }
  }
  onFound?.(out.length);
  return out;
}

export async function parseSessionFile(
  filePath: string,
  signal?: AbortSignal,
): Promise<ParsedSession | null> {
  const fileName = path.basename(filePath);
  let startedAt = parseSessionStartFromFilename(fileName);
  let currentModel: ModelKey | null = null;
  let cwd: string | null = null;

  const modelsUsed = new Set<ModelKey>();
  let messages = 0;
  let tokens = 0;
  let totalCost = 0;
  const costByModel = new Map<ModelKey, number>();
  const messagesByModel = new Map<ModelKey, number>();
  const tokensByModel = new Map<ModelKey, number>();

  const stream = createReadStream(filePath, { encoding: "utf8" });
  const rl = readline.createInterface({ input: stream, crlfDelay: Infinity });

  try {
    for await (const line of rl) {
      if (signal?.aborted) {
        rl.close();
        stream.destroy();
        return null;
      }
      if (!line) continue;
      let obj: any;
      try {
        obj = JSON.parse(line);
      } catch {
        continue;
      }

      if (obj?.type === "session") {
        if (!startedAt && typeof obj?.timestamp === "string") {
          const d = new Date(obj.timestamp);
          if (Number.isFinite(d.getTime())) startedAt = d;
        }
        if (typeof obj?.cwd === "string" && obj.cwd.trim()) {
          cwd = obj.cwd.trim();
        }
        continue;
      }

      if (obj?.type === "model_change") {
        const mk = modelKeyFromParts(obj.provider, obj.modelId);
        if (mk) {
          currentModel = mk;
          modelsUsed.add(mk);
        }
        continue;
      }

      if (obj?.type !== "message") continue;

      const { provider, model, modelId, usage } =
        extractProviderModelAndUsage(obj);
      const mk =
        modelKeyFromParts(provider, model) ??
        modelKeyFromParts(provider, modelId) ??
        currentModel ??
        "unknown";
      modelsUsed.add(mk);

      messages += 1;
      messagesByModel.set(mk, (messagesByModel.get(mk) ?? 0) + 1);

      const tok = extractTokensTotal(usage);
      if (tok > 0) {
        tokens += tok;
        tokensByModel.set(mk, (tokensByModel.get(mk) ?? 0) + tok);
      }

      const cost = extractCostTotal(usage);
      if (cost > 0) {
        totalCost += cost;
        costByModel.set(mk, (costByModel.get(mk) ?? 0) + cost);
      }
    }
  } finally {
    rl.close();
    stream.destroy();
  }

  if (!startedAt) return null;
  const dayKeyLocal = toLocalDayKey(startedAt);
  const dow = DOW_NAMES[mondayIndex(startedAt)];
  const tod = todBucketForHour(startedAt.getHours());
  return {
    filePath,
    startedAt,
    dayKeyLocal,
    cwd,
    dow,
    tod,
    modelsUsed,
    messages,
    tokens,
    totalCost,
    costByModel,
    messagesByModel,
    tokensByModel,
  };
}
