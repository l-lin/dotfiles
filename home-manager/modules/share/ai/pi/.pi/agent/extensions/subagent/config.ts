/** Reads ~/.pi/agent/subagents.json to provide configurable defaults. */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

export interface SubagentConfig {
  /** Directories to search for agent definitions. Supports ~ and $HOME expansion; relative paths resolve against cwd. Default: ["~/.pi/agent/agents"]. */
  sources: string[];
  /** Maximum number of sub-agents that can be spawned in parallel per spawn call. Default: 4. */
  maxParallel: number;
}

const DEFAULTS: SubagentConfig = {
  sources: ["~/.pi/agent/agents", "./.pi/agents"],
  maxParallel: 4,
};

const CONFIG_PATH = path.join(os.homedir(), ".pi", "agent", "subagents.json");

/** Loads config from disk each call so changes are picked up without restart. */
export function loadConfig(): SubagentConfig {
  try {
    const raw = fs.readFileSync(CONFIG_PATH, "utf-8");
    const parsed = JSON.parse(raw) as Partial<SubagentConfig>;
    return {
      sources: isValidSources(parsed.sources) ? parsed.sources : DEFAULTS.sources,
      maxParallel: typeof parsed.maxParallel === "number" && parsed.maxParallel > 0
        ? Math.floor(parsed.maxParallel)
        : DEFAULTS.maxParallel,
    };
  } catch {
    // File missing or malformed — fall back to defaults silently
    return { ...DEFAULTS };
  }
}

function isValidSources(v: unknown): v is string[] {
  return Array.isArray(v) && v.length > 0 && v.every((s) => typeof s === "string" && s.length > 0);
}
