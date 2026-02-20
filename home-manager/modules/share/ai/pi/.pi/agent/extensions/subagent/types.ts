export interface SpawnResult {
  id: string;
  agent: string;
  /** Resolved absolute path of the source directory */
  agentSource: string;
  paneId: string;
}

export interface SubagentDetails {
  action: string;
  sources?: string[];
  spawned?: SpawnResult[];
  sessionId?: string;
  result?: string;
}
