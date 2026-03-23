import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import path from "node:path";
import fs from "node:fs/promises";
import { existsSync } from "node:fs";
import type { SkillIndexEntry } from "./types.js";
import {
  estimateTokens,
  getAgentDir,
  normalizeReadPath,
  normalizeSkillName,
} from "./utils.js";

async function readFileIfExists(
  filePath: string,
): Promise<{ path: string; content: string; bytes: number } | null> {
  if (!existsSync(filePath)) return null;
  try {
    const buf = await fs.readFile(filePath);
    return {
      path: filePath,
      content: buf.toString("utf8"),
      bytes: buf.byteLength,
    };
  } catch {
    return null;
  }
}

async function tryLoadContextFile(
  dir: string,
  seen: Set<string>,
): Promise<{ path: string; tokens: number; bytes: number } | null> {
  for (const fileName of ["AGENTS.md", "CLAUDE.md"]) {
    const filePath = path.join(dir, fileName);
    const file = await readFileIfExists(filePath);

    if (file && !seen.has(file.path)) {
      seen.add(file.path);
      return {
        path: file.path,
        tokens: estimateTokens(file.content),
        bytes: file.bytes,
      };
    }
  }
  return null;
}

function getAncestorDirectories(cwd: string): string[] {
  const directories: string[] = [];
  let current = path.resolve(cwd);

  while (true) {
    directories.push(current);
    const parent = path.resolve(current, "..");
    if (parent === current) break;
    current = parent;
  }

  return directories.reverse();
}

export async function loadProjectContextFiles(
  cwd: string,
): Promise<Array<{ path: string; tokens: number; bytes: number }>> {
  const contextFiles: Array<{ path: string; tokens: number; bytes: number }> =
    [];
  const seen = new Set<string>();

  // Load from agent directory first
  const agentFile = await tryLoadContextFile(getAgentDir(), seen);
  if (agentFile) contextFiles.push(agentFile);

  // Load from cwd ancestors
  for (const dir of getAncestorDirectories(cwd)) {
    const file = await tryLoadContextFile(dir, seen);
    if (file) contextFiles.push(file);
  }

  return contextFiles;
}

export function buildSkillIndex(
  pi: ExtensionAPI,
  cwd: string,
): SkillIndexEntry[] {
  return pi
    .getCommands()
    .filter((command) => command.source === "skill")
    .map((command) => {
      const skillFilePath = command.sourceInfo.path
        ? normalizeReadPath(command.sourceInfo.path, cwd)
        : "";

      return {
        name: normalizeSkillName(command.name),
        skillFilePath,
        skillDir: skillFilePath ? path.dirname(skillFilePath) : "",
      };
    })
    .filter((entry) => entry.name && entry.skillDir);
}
