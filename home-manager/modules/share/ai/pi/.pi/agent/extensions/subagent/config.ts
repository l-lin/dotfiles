/** Reads ~/.pi/agent/settings.json (extensionSettings.subagent property) to provide configurable defaults. */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

export interface UserSystemPromptConfig {
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
  /** Whether the subagent tool is enabled. Default: true. */
  enabled: boolean;
}

const DEFAULTS: SubagentConfig = {
  sources: ["~/.pi/agent/agents", "./.pi/agents"],
  maxParallel: 5,
  userSystemPrompt: {
    path: "~/.pi/agent/AGENTS.md",
  },
  enabled: true,
};

const CONFIG_PATH = path.join(os.homedir(), ".pi", "agent", "settings.json");

/** Loads config from disk each call so changes are picked up without restart. */
export function loadConfig(): SubagentConfig {
  try {
    const raw = fs.readFileSync(CONFIG_PATH, "utf-8");
    const settings = JSON.parse(raw) as {
      extensionSettings?: { subagent?: Partial<SubagentConfig> };
    };
    const parsed = settings.extensionSettings?.subagent || {};
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
        path:
          typeof usp?.path === "string" && usp.path.length > 0
            ? usp.path
            : DEFAULTS.userSystemPrompt.path,
      },
      enabled:
        typeof parsed.enabled === "boolean" ? parsed.enabled : DEFAULTS.enabled,
    };
  } catch {
    return {
      ...DEFAULTS,
      userSystemPrompt: { ...DEFAULTS.userSystemPrompt },
    };
  }
}

export function saveEnabled(enabled: boolean): void {
  let settings: Record<string, unknown> = {};
  try {
    settings = JSON.parse(fs.readFileSync(CONFIG_PATH, "utf-8"));
  } catch {
    // File missing or malformed — start fresh
  }
  const extensionSettings = (settings.extensionSettings ?? {}) as Record<
    string,
    unknown
  >;
  const existing = (extensionSettings.subagent ?? {}) as Record<
    string,
    unknown
  >;
  extensionSettings.subagent = { ...existing, enabled };
  settings.extensionSettings = extensionSettings;
  fs.mkdirSync(path.dirname(CONFIG_PATH), { recursive: true });
  fs.writeFileSync(
    CONFIG_PATH,
    JSON.stringify(settings, null, 2) + "\n",
    "utf-8",
  );
}

function isValidSources(v: unknown): v is string[] {
  return (
    Array.isArray(v) &&
    v.length > 0 &&
    v.every((s) => typeof s === "string" && s.length > 0)
  );
}
