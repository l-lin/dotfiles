import type { AgentScope } from "./agents.js";

export interface SpawnResult {
  id: string;
  agent: string;
  agentSource: "user" | "project";
  paneId: string;
}

export interface SubagentDetails {
  action: string;
  agentScope?: AgentScope;
  spawned?: SpawnResult[];
  sessionId?: string;
  result?: string;
}
