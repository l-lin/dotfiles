/** Reads ~/.pi/agent/settings.json (extensionSettings.subagent property) to provide configurable defaults. */

import {
  readExtensionSettings,
  saveExtensionSettings,
} from "../tool-settings/index.js";

export interface UserSystemPromptSettings {
  /** Path to a user-level system prompt prepended to every subagent's prompt. Supports ~ expansion. Default: "~/.pi/agent/AGENTS.md". */
  path: string;
}

export interface SubagentSettings {
  /** Directories to search for agent definitions. Supports ~ and $HOME expansion; relative paths resolve against cwd. Default: ["~/.pi/agent/agents"]. */
  sources: string[];
  /** Maximum number of subagents that can be spawned in parallel per spawn call. Default: 4. */
  maxParallel: number;
  /** User-level system prompt settings. */
  userSystemPrompt: UserSystemPromptSettings;
  /** Whether the subagent tool is enabled. Default: true. */
  enabled: boolean;
}

const DEFAULTS: SubagentSettings = {
  sources: ["~/.pi/agent/agents", "./.pi/agents"],
  maxParallel: 5,
  userSystemPrompt: {
    path: "~/.pi/agent/AGENTS.md",
  },
  enabled: true,
};

const SETTINGS_KEY = "subagent";

/** Loads settings from disk each call so changes are picked up without restart. */
export function loadSettings(): SubagentSettings {
  const parsed = readExtensionSettings<SubagentSettings>(SETTINGS_KEY);
  const userSystemPrompt = parsed.userSystemPrompt;

  return {
    sources: isValidSources(parsed.sources) ? parsed.sources : DEFAULTS.sources,
    maxParallel:
      typeof parsed.maxParallel === "number" && parsed.maxParallel > 0
        ? Math.floor(parsed.maxParallel)
        : DEFAULTS.maxParallel,
    userSystemPrompt: {
      path:
        typeof userSystemPrompt?.path === "string" &&
        userSystemPrompt.path.length > 0
          ? userSystemPrompt.path
          : DEFAULTS.userSystemPrompt.path,
    },
    enabled:
      typeof parsed.enabled === "boolean" ? parsed.enabled : DEFAULTS.enabled,
  };
}

export function saveEnabled(enabled: boolean): void {
  saveExtensionSettings({
    extensionKey: SETTINGS_KEY,
    enabled,
  });
}

function isValidSources(value: unknown): value is string[] {
  return (
    Array.isArray(value) &&
    value.length > 0 &&
    value.every((source) => typeof source === "string" && source.length > 0)
  );
}
