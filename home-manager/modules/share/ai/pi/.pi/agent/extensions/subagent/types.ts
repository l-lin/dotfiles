// ============================================================================
// Subagent Extension — Type Definitions & Constants
// ============================================================================

import type * as fs from "node:fs";

export const ICONS = {
  agent: "󰚩",
  stopped: "󱚧",
  send: "󱃜",
  report: "󱃚",
  pending: "",
  done: "",
} as const;

export enum Action {
  Spawn = "spawn",
  Send = "send",
  Read = "read",
  Close = "close",
  Catalog = "catalog",
  List = "list",
  AllDone = "all-done",
}

export interface SpawnResult {
  id: string;
  agent: string;
  /** Resolved absolute path of the source directory */
  agentSource: string;
  paneId: string;
}

export interface SubagentDetails {
  action: Action;
  sources?: string[];
  spawned?: SpawnResult[];
  sessionId?: string;
  result?: string;
  count?: number;
}

export interface Session {
  id: string;
  agentName: string;
  /** Resolved absolute path of the source directory */
  agentSource: string;
  task: string;
  paneId: string;
  resultFile: string;
  lastResult: string;
  alive: boolean;
  /** True while waiting for a response (after spawn or send, cleared on result delivery) */
  pending: boolean;
  watcher?: fs.FSWatcher;
}

export interface AgentSettings {
  name: string;
  description: string;
  tools?: string[];
  model?: string;
  /** Whether to append user system prompt (default: true) */
  appendUserSystemPrompt?: boolean;
  systemPrompt: string;
  /** Resolved absolute path of the source directory */
  source: string;
  filePath: string;
}

export interface AgentDiscoveryResult {
  agents: AgentSettings[];
}

export interface ToolResult {
  content: { type: "text"; text: string }[];
  isError?: boolean;
  details: SubagentDetails;
}
