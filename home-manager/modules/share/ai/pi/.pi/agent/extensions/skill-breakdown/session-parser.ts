import path from "node:path";
import fs from "node:fs/promises";
import { createReadStream, type Dirent } from "node:fs";
import readline from "node:readline";
import { isSkillPath, skillNameFromPath } from "../active-skills/tracker.js";
import { SKILL_LOADED_ENTRY } from "../context/types.js";
import { localMidnight } from "../session-breakdown/date-utils.js";
import {
  modelKeyFromParts,
  parseSessionStartFromFilename,
} from "../session-breakdown/session-parser.js";
import type {
  ModelKey,
  ParsedSkillSession,
  ProjectKey,
  SkillName,
} from "./types.js";

interface PendingSkillRead {
  skillName: SkillName;
  model: ModelKey | null;
}

function parseTimestamp(value: unknown): Date | null {
  if (typeof value !== "string" && typeof value !== "number") return null;
  const date = new Date(value);
  return Number.isFinite(date.getTime()) ? date : null;
}

function extractMessageModel(
  obj: any,
  currentModel: ModelKey | null,
): ModelKey | null {
  const message = obj?.message;
  return (
    modelKeyFromParts(
      obj?.provider ?? message?.provider,
      obj?.model ?? message?.model,
    ) ??
    modelKeyFromParts(
      obj?.provider ?? message?.provider,
      obj?.modelId ?? message?.modelId,
    ) ??
    currentModel
  );
}

function extractLoadedSkillName(entry: any): string {
  const explicitName = entry?.data?.name;
  if (typeof explicitName === "string" && explicitName.trim()) {
    return explicitName.trim();
  }

  const loadedPath = entry?.data?.path;
  if (typeof loadedPath === "string" && isSkillPath(loadedPath)) {
    return skillNameFromPath(loadedPath);
  }

  return "";
}

function resolveSkillTimestamp(
  entryTimestamp: unknown,
  sessionStartedAt: Date | null,
): Date | null {
  return parseTimestamp(entryTimestamp) ?? sessionStartedAt;
}

function recordSkillLoad(
  skillFirstLoadedAt: Map<SkillName, Date>,
  skillProjectByName: Map<SkillName, ProjectKey | null>,
  skillModelByName: Map<SkillName, ModelKey | null>,
  skillName: string,
  timestamp: Date | null,
  project: ProjectKey | null,
  model: ModelKey | null,
): void {
  const normalizedName = typeof skillName === "string" ? skillName.trim() : "";
  if (!normalizedName || !timestamp) return;

  const existing = skillFirstLoadedAt.get(normalizedName);
  if (existing && existing <= timestamp) return;

  skillFirstLoadedAt.set(normalizedName, timestamp);
  skillProjectByName.set(normalizedName, project);
  skillModelByName.set(normalizedName, model);
}

export async function walkRecentSessionFiles(
  root: string,
  startCutoffLocal: Date,
  signal?: AbortSignal,
  onFound?: (found: number) => void,
): Promise<string[]> {
  const candidates: string[] = [];
  const stack: string[] = [root];

  while (stack.length > 0) {
    if (signal?.aborted) break;

    const directory = stack.pop()!;
    let entries: Dirent[] = [];
    try {
      entries = await fs.readdir(directory, { withFileTypes: true });
    } catch {
      continue;
    }

    for (const entry of entries) {
      if (signal?.aborted) break;

      const filePath = path.join(directory, entry.name);
      if (entry.isDirectory()) {
        stack.push(filePath);
        continue;
      }
      if (!entry.isFile() || !entry.name.endsWith(".jsonl")) continue;

      let includeFile = false;
      const startedAt = parseSessionStartFromFilename(entry.name);
      if (startedAt && localMidnight(startedAt) >= startCutoffLocal) {
        includeFile = true;
      }

      if (!includeFile) {
        try {
          const stats = await fs.stat(filePath);
          includeFile =
            localMidnight(new Date(stats.mtimeMs)) >= startCutoffLocal;
        } catch {
          includeFile = false;
        }
      }

      if (!includeFile) continue;

      candidates.push(filePath);
      if (onFound && candidates.length % 10 === 0) onFound(candidates.length);
    }
  }

  onFound?.(candidates.length);
  return candidates;
}

export async function parseSkillSessionFile(
  filePath: string,
  signal?: AbortSignal,
): Promise<ParsedSkillSession | null> {
  const fileName = path.basename(filePath);
  let sessionStartedAt = parseSessionStartFromFilename(fileName);
  let currentProject: ProjectKey | null = null;
  let currentModel: ModelKey | null = null;

  const pendingSkillReads = new Map<string, PendingSkillRead>();
  const skillFirstLoadedAt = new Map<SkillName, Date>();
  const skillProjectByName = new Map<SkillName, ProjectKey | null>();
  const skillModelByName = new Map<SkillName, ModelKey | null>();

  const stream = createReadStream(filePath, { encoding: "utf8" });
  const reader = readline.createInterface({
    input: stream,
    crlfDelay: Infinity,
  });

  try {
    for await (const line of reader) {
      if (signal?.aborted) {
        reader.close();
        stream.destroy();
        return null;
      }
      if (!line) continue;

      let entry: any;
      try {
        entry = JSON.parse(line);
      } catch {
        continue;
      }

      if (entry?.type === "session") {
        if (!sessionStartedAt)
          sessionStartedAt = parseTimestamp(entry.timestamp);
        if (typeof entry?.cwd === "string" && entry.cwd.trim()) {
          currentProject = entry.cwd.trim();
        }
        continue;
      }

      if (entry?.type === "model_change") {
        currentModel =
          modelKeyFromParts(entry?.provider, entry?.modelId) ?? currentModel;
        continue;
      }

      if (
        entry?.type === "custom" &&
        entry?.customType === SKILL_LOADED_ENTRY
      ) {
        recordSkillLoad(
          skillFirstLoadedAt,
          skillProjectByName,
          skillModelByName,
          extractLoadedSkillName(entry),
          resolveSkillTimestamp(entry.timestamp, sessionStartedAt),
          currentProject,
          currentModel,
        );
        continue;
      }

      if (entry?.type !== "message") continue;

      const message = entry.message;
      const messageModel = extractMessageModel(entry, currentModel);
      if (messageModel) currentModel = messageModel;

      if (message?.role === "assistant" && Array.isArray(message?.content)) {
        for (const block of message.content) {
          if (block?.type !== "toolCall" || block?.name !== "read") continue;

          const toolCallId = typeof block?.id === "string" ? block.id : "";
          const readPath = block?.arguments?.path;
          if (
            !toolCallId ||
            typeof readPath !== "string" ||
            !isSkillPath(readPath)
          ) {
            continue;
          }

          pendingSkillReads.set(toolCallId, {
            skillName: skillNameFromPath(readPath),
            model: currentModel,
          });
        }
        continue;
      }

      if (message?.role !== "toolResult") continue;
      if (message?.toolName !== "read" || message?.isError === true) continue;

      const toolCallId =
        typeof message?.toolCallId === "string" ? message.toolCallId : "";
      const pendingRead = pendingSkillReads.get(toolCallId);
      if (!pendingRead) continue;

      recordSkillLoad(
        skillFirstLoadedAt,
        skillProjectByName,
        skillModelByName,
        pendingRead.skillName,
        resolveSkillTimestamp(entry.timestamp, sessionStartedAt),
        currentProject,
        pendingRead.model ?? currentModel,
      );
    }
  } finally {
    reader.close();
    stream.destroy();
  }

  if (skillFirstLoadedAt.size === 0) return null;

  return {
    filePath,
    skillFirstLoadedAt,
    skillProjectByName,
    skillModelByName,
  };
}
