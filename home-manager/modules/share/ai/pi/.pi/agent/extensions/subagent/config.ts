/** Reads ~/.pi/agent/settings.json (subagent property) to provide configurable defaults. */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

export interface UserSystemPromptConfig {
  /** Whether to prepend the user system prompt to every subagent's prompt. Default: true. */
  enabled: boolean;
  /** Path to a user-level system prompt prepended to every subagent's prompt. Supports ~ expansion. Default: "~/.pi/agent/AGENTS.md". */
  path: string;
}

export interface SubagentConfig {
  /** Directories to search for agent definitions. Supports ~ and $HOME expansion; relative paths resolve against cwd. Default: ["~/.pi/agent/agents"]. */
  sources: string[];
  /** Maximum number of subagents that can be spawned in parallel per spawn call. Default: 4. */
  maxParallel: number;
  /** User-level system prompt configuration. */
  userSystemPrompt: UserSystemPromptConfig;
}

const DEFAULTS: SubagentConfig = {
  sources: ["~/.pi/agent/agents", "./.pi/agents"],
  maxParallel: 5,
  userSystemPrompt: {
    enabled: true,
    path: "~/.pi/agent/AGENTS.md",
  },
};

const CONFIG_PATH = path.join(os.homedir(), ".pi", "agent", "settings.json");

/** Loads config from disk each call so changes are picked up without restart. */
export function loadConfig(): SubagentConfig {
  try {
    const raw = fs.readFileSync(CONFIG_PATH, "utf-8");
    const settings = JSON.parse(raw) as { subagent?: Partial<SubagentConfig> };
    const parsed = settings.subagent || {};
    const usp = parsed.userSystemPrompt;
    return {
      sources: isValidSources(parsed.sources)
        ? parsed.sources
        : DEFAULTS.sources,
      maxParallel:
        typeof parsed.maxParallel === "number" && parsed.maxParallel > 0
          ? Math.floor(parsed.maxParallel)
          : DEFAULTS.maxParallel,
      userSystemPrompt: {
        enabled:
          typeof usp?.enabled === "boolean"
            ? usp.enabled
            : DEFAULTS.userSystemPrompt.enabled,
        path:
          typeof usp?.path === "string" && usp.path.length > 0
            ? usp.path
            : DEFAULTS.userSystemPrompt.path,
      },
    };
  } catch {
    // File missing or malformed — fall back to defaults silently
    return { ...DEFAULTS, userSystemPrompt: { ...DEFAULTS.userSystemPrompt } };
  }
}

function isValidSources(v: unknown): v is string[] {
  return (
    Array.isArray(v) &&
    v.length > 0 &&
    v.every((s) => typeof s === "string" && s.length > 0)
  );
}
