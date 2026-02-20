/** Reads ~/.pi/agent/subagents.json to provide configurable defaults. */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { AgentScope } from "./agents.js";

export interface SubagentConfig {
  /** Which agent directories to search. "user" = ~/.pi/agent/agents, "project" = .pi/agents, "both" = merge both. Default: "user". */
  agentScope: AgentScope;
  /** Maximum number of sub-agents that can be spawned in parallel per spawn call. Default: 4. */
  maxParallel: number;
}

const DEFAULTS: SubagentConfig = {
  agentScope: "user",
  maxParallel: 4,
};

const CONFIG_PATH = path.join(os.homedir(), ".pi", "agent", "subagents.json");

/** Loads config from disk each call so changes are picked up without restart. */
export function loadConfig(): SubagentConfig {
  try {
    const raw = fs.readFileSync(CONFIG_PATH, "utf-8");
    const parsed = JSON.parse(raw) as Partial<SubagentConfig>;
    return {
      agentScope: isValidScope(parsed.agentScope) ? parsed.agentScope : DEFAULTS.agentScope,
      maxParallel: typeof parsed.maxParallel === "number" && parsed.maxParallel > 0
        ? Math.floor(parsed.maxParallel)
        : DEFAULTS.maxParallel,
    };
  } catch {
    // File missing or malformed — fall back to defaults silently
    return { ...DEFAULTS };
  }
}

function isValidScope(v: unknown): v is AgentScope {
  return v === "user" || v === "project" || v === "both";
}
