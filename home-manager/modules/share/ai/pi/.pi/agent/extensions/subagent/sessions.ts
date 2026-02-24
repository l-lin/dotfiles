/** Sub-agent session lifecycle: spawn, track, close */

import { execSync } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import type { AgentConfig } from "./agents.js";
import * as tmux from "./tmux.js";

// ─── shared types ────────────────────────────────────────────────────────────

export enum Action {
  Spawn = "spawn",
  Send = "send",
  Read = "read",
  Close = "close",
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

// ─── session type ────────────────────────────────────────────────────────────

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

// ─── pending pool ─────────────────────────────────────────────────────────────
// A single flat pool accumulates all spawned sessions regardless of how many
// spawn calls the agent makes. Consolidated fires once when ≥2 sessions have
// all reported. Resets automatically when a new spawn starts and the previous
// pool was already complete (all results in).

interface PoolEntry {
  agentName: string;
  result: string | null;
}

const pendingPool = new Map<string, PoolEntry>();
let poolTriggered = false;

/**
 * Register newly spawned session IDs into the pool.
 * If the previous pool cycle is complete (all results collected), it is reset
 * first so unrelated future spawns start clean.
 */
export function registerGroup(ids: string[]): void {
  if (ids.length === 0) return;
  const prevComplete =
    poolTriggered ||
    (pendingPool.size > 0 &&
      [...pendingPool.values()].every((e) => e.result !== null));
  if (prevComplete) {
    pendingPool.clear();
    poolTriggered = false;
  }
  for (const id of ids) {
    pendingPool.set(id, { agentName: "", result: null });
  }
}

/**
 * Record a result for a session. Fires the "all done" trigger once every
 * session in the pool has reported (works for both single and parallel spawns).
 * Safe to call multiple times — idempotent after pool fires.
 */
function flushToPool(
  sessionId: string,
  agentName: string,
  result: string,
  pi: ExtensionAPI,
): void {
  const entry = pendingPool.get(sessionId);
  if (!entry) return;
  entry.agentName = agentName;
  entry.result = result;

  if (poolTriggered) return;

  const allDone = [...pendingPool.values()].every((e) => e.result !== null);
  if (!allDone) return;

  poolTriggered = true;

  const count = pendingPool.size;
  const content =
    count === 1
      ? "Sub-agent has reported. Now use the result to complete your task."
      : "All sub-agents have reported. Now synthesize these results and complete your task.";

  pi.sendMessage(
    {
      customType: "subagent-result",
      content,
      display: true,
      details: { action: Action.AllDone },
    },
    { triggerTurn: true, deliverAs: "followUp" },
  );
}

// ─── state ───────────────────────────────────────────────────────────────────

const sessions = new Map<string, Session>();
let subagentWindowId: string | undefined;
let piRef: ExtensionAPI | undefined;

export function get(id: string): Session | undefined {
  return sessions.get(id);
}

export function all(): Session[] {
  return [...sessions.values()];
}

export function ids(): string[] {
  return [...sessions.keys()];
}

export function size(): number {
  return sessions.size;
}

// ─── spawn ───────────────────────────────────────────────────────────────────

function generateId(agentName: string): string {
  return `${agentName}-${Math.random().toString(36).slice(2, 6)}`;
}

function sessionDir(id: string): string {
  const homeDir = os.homedir();
  return path.join(homeDir, ".local", "share", "pi", "subagent", id);
}

function writeBadgeExtension(
  dir: string,
  sessionId: string,
  task: string,
): string {
  const file = path.join(dir, "badge-extension.ts");
  // Embed values as JSON strings so all escaping is handled correctly
  const i = JSON.stringify(sessionId);
  const t = JSON.stringify(task.length > 120 ? `${task.slice(0, 120)}…` : task);
  const content = `\
export default function (pi: any) {
  pi.on("session_start", async (_event: any, ctx: any) => {
    const id   = ${i};
    const task = ${t};
    ctx.ui.setWidget("subagent-badge", (_tui: any, theme: any) => ({
      render: (width: number) => {
        const dot = "󰚩 ";
        const dotWidth = 3;
        const sep = " ";
        const available = Math.max(0, width - dotWidth - id.length - sep.length);
        const taskStr = available <= 0 ? "" : task.length > available ? task.slice(0, available - 1) + "…" : task;
        return [theme.fg("dim", dot) + theme.fg("toolTitle", theme.bold(id)) + theme.fg("dim", sep + taskStr)];
      },
      invalidate: () => {},
    }), { placement: "belowEditor" });
  });
}
`;
  fs.writeFileSync(file, content, { encoding: "utf-8", mode: 0o600 });
  return file;
}

function buildPiCommand(
  agent: AgentConfig,
  task: string,
  resultFile: string,
  systemPromptFile?: string,
  badgeExtensionFile?: string,
): string {
  const parts: string[] = ["pi"];

  if (agent.model) parts.push("--model", tmux.esc(agent.model));

  const tools = agent.tools ? [...agent.tools] : undefined;
  if (tools && !tools.includes("write")) tools.push("write");
  if (tools?.length) parts.push("--tools", tmux.esc(tools.join(",")));

  if (systemPromptFile)
    parts.push("--system-prompt", tmux.esc(systemPromptFile));
  if (badgeExtensionFile)
    parts.push("--extension", tmux.esc(badgeExtensionFile));
  parts.push("--no-session");

  const augmented = `${task}

IMPORTANT COMMUNICATION PROTOCOL:
When you have completed the task (or have a meaningful intermediate result to report), write your answer/summary to "${resultFile}" using the write tool. This file is monitored by the parent agent — writing to it automatically notifies them. You can update this file multiple times as you make progress. Always do a final write before you finish.`;

  parts.push(tmux.esc(`Task: ${augmented}`));
  return parts.join(" ");
}

export function spawn(
  pi: ExtensionAPI,
  agent: AgentConfig,
  task: string,
  cwd: string,
): Session {
  piRef = pi;
  const id = generateId(agent.name);
  const dir = sessionDir(id);
  fs.mkdirSync(dir, { recursive: true });

  const resultFile = path.join(dir, "result.md");

  let systemPromptFile: string | undefined;
  if (agent.systemPrompt.trim()) {
    systemPromptFile = path.join(
      dir,
      `prompt-${agent.name.replace(/[^\w.-]+/g, "_")}.md`,
    );
    fs.writeFileSync(systemPromptFile, agent.systemPrompt, {
      encoding: "utf-8",
      mode: 0o600,
    });
  }

  const badgeExtensionFile = writeBadgeExtension(dir, id, task);

  // First subagent creates a new window, subsequent ones split within it
  let paneId: string;
  if (!subagentWindowId || sessions.size === 0) {
    paneId = tmux.createWindow(cwd, "subagents");
    subagentWindowId = tmux.getWindowId(paneId);
  } else {
    // Get any existing pane in the subagent window to split from
    const existingSession = sessions.values().next().value as Session;
    paneId = tmux.splitPane(existingSession.paneId, cwd);
  }

  // HACK: wait for shell to finish initializing before sending command
  execSync("sleep 1.5");
  tmux.sendCommand(
    paneId,
    buildPiCommand(
      agent,
      task,
      resultFile,
      systemPromptFile,
      badgeExtensionFile,
    ),
  );

  const session: Session = {
    id,
    agentName: agent.name,
    agentSource: agent.source,
    task,
    paneId,
    resultFile,
    lastResult: "",
    alive: true,
    pending: true,
  };

  // Watch result file for changes (directory watch since file doesn't exist yet)
  try {
    session.watcher = fs.watch(dir, (_event, filename) => {
      if (filename !== "result.md") return;
      let content: string;
      try {
        content = fs.readFileSync(resultFile, "utf-8").trim();
      } catch {
        return;
      }
      if (!content || content === session.lastResult) return;
      session.lastResult = content;
      session.pending = false;

      // Deliver individual result visibly but don't wake the main agent yet
      pi.sendMessage(
        {
          customType: "subagent-result",
          content: `Sub-agent "${id}" reported:\n\n${content}`,
          display: true,
          details: { sessionId: id, agentName: agent.name },
        },
        { triggerTurn: false, deliverAs: "followUp" },
      );

      flushToPool(id, agent.name, content, pi);
    });
  } catch {
    /* watcher failure is non-fatal — use explicit read */
  }

  sessions.set(id, session);
  return session;
}

// ─── close ───────────────────────────────────────────────────────────────────

export function close(session: Session): void {
  // Flush last known result into the pool before the watcher is stopped,
  // so the consolidated trigger can still fire even if close() races the watcher.
  if (session.lastResult && piRef) {
    flushToPool(session.id, session.agentName, session.lastResult, piRef);
  }
  session.alive = false;
  session.watcher?.close();
  tmux.killPane(session.paneId);
  try {
    fs.rmSync(sessionDir(session.id), { recursive: true, force: true });
  } catch {
    /* ignore */
  }
  sessions.delete(session.id);

  // Clear window tracking when all sessions are closed
  if (sessions.size === 0) {
    subagentWindowId = undefined;
  }
}

export function closeAll(): void {
  for (const s of all()) close(s);
  subagentWindowId = undefined;
  pendingPool.clear();
  poolTriggered = false;
}

// ─── helpers ─────────────────────────────────────────────────────────────────

/** Re-read result file (compensates for missed fs.watch events) */
export function refreshResult(session: Session): string {
  try {
    const content = fs.readFileSync(session.resultFile, "utf-8").trim();
    if (content) session.lastResult = content;
  } catch {
    /* file may not exist yet */
  }
  return session.lastResult;
}

export function checkAlive(session: Session): boolean {
  const alive = session.alive && tmux.paneAlive(session.paneId);
  if (!alive) session.alive = false;
  return alive;
}
