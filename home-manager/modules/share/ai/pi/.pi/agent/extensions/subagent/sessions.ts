/** Sub-agent session lifecycle: spawn, track, close */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import type { AgentConfig } from "./agents.js";
import * as tmux from "./tmux.js";

// ─── types ───────────────────────────────────────────────────────────────────

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
  watcher?: fs.FSWatcher;
}

// ─── state ───────────────────────────────────────────────────────────────────

const sessions = new Map<string, Session>();

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
  const safe = agentName.replace(/[^\w]/g, "").slice(0, 12);
  return `${safe}-${Math.random().toString(36).slice(2, 6)}`;
}

function sessionDir(id: string): string {
  return path.join(os.tmpdir(), `pi-subagent-${id}`);
}

function writeBadgeExtension(dir: string, sessionId: string, task: string): string {
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
        return [theme.fg("success", dot) + theme.fg("toolTitle", theme.bold(id)) + theme.fg("dim", sep + taskStr)];
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
  const esc = (s: string) => `'${s.replace(/'/g, "'\\''")}'`;
  const parts: string[] = ["pi"];

  if (agent.model) parts.push("--model", esc(agent.model));

  const tools = agent.tools ? [...agent.tools] : undefined;
  if (tools && !tools.includes("write")) tools.push("write");
  if (tools?.length) parts.push("--tools", esc(tools.join(",")));

  if (systemPromptFile) parts.push("--append-system-prompt", esc(systemPromptFile));
  if (badgeExtensionFile) parts.push("--extension", esc(badgeExtensionFile));
  parts.push("--no-session");

  const augmented = `${task}

IMPORTANT COMMUNICATION PROTOCOL:
When you have completed the task (or have a meaningful intermediate result to report), write your answer/summary to "${resultFile}" using the write tool. This file is monitored by the parent agent — writing to it automatically notifies them. You can update this file multiple times as you make progress. Always do a final write before you finish.`;

  parts.push(esc(`Task: ${augmented}`));
  return parts.join(" ");
}

export function spawn(pi: ExtensionAPI, agent: AgentConfig, task: string, cwd: string): Session {
  const id = generateId(agent.name);
  const dir = sessionDir(id);
  fs.mkdirSync(dir, { recursive: true });

  const resultFile = path.join(dir, "result.md");

  let systemPromptFile: string | undefined;
  if (agent.systemPrompt.trim()) {
    systemPromptFile = path.join(dir, `prompt-${agent.name.replace(/[^\w.-]+/g, "_")}.md`);
    fs.writeFileSync(systemPromptFile, agent.systemPrompt, { encoding: "utf-8", mode: 0o600 });
  }

  const badgeExtensionFile = writeBadgeExtension(dir, id, task);

  const paneId = tmux.splitRight(cwd);
  tmux.sendCommand(paneId, buildPiCommand(agent, task, resultFile, systemPromptFile, badgeExtensionFile));

  const session: Session = {
    id,
    agentName: agent.name,
    agentSource: agent.source,
    task,
    paneId,
    resultFile,
    lastResult: "",
    alive: true,
  };

  // Watch result file for changes (directory watch since file doesn't exist yet)
  try {
    session.watcher = fs.watch(dir, (_event, filename) => {
      if (filename !== "result.md") return;
      let content: string;
      try { content = fs.readFileSync(resultFile, "utf-8").trim(); } catch { return; }
      if (!content || content === session.lastResult) return;
      session.lastResult = content;

      pi.sendMessage(
        {
          customType: "subagent-result",
          content: `Sub-agent "${id}" reported:\n\n${content}`,
          display: true,
          details: { sessionId: id, agentName: agent.name },
        },
        { triggerTurn: true, deliverAs: "followUp" },
      );
    });
  } catch { /* watcher failure is non-fatal — use explicit read */ }

  sessions.set(id, session);
  return session;
}

// ─── close ───────────────────────────────────────────────────────────────────

export function close(session: Session): void {
  session.alive = false;
  session.watcher?.close();
  tmux.killPane(session.paneId);
  try { fs.rmSync(sessionDir(session.id), { recursive: true, force: true }); } catch { /* ignore */ }
  sessions.delete(session.id);
}

export function closeAll(): void {
  for (const s of all()) close(s);
}

// ─── helpers ─────────────────────────────────────────────────────────────────

/** Re-read result file (compensates for missed fs.watch events) */
export function refreshResult(session: Session): string {
  try {
    const content = fs.readFileSync(session.resultFile, "utf-8").trim();
    if (content) session.lastResult = content;
  } catch { /* file may not exist yet */ }
  return session.lastResult;
}

export function checkAlive(session: Session): boolean {
  const alive = session.alive && tmux.paneAlive(session.paneId);
  if (!alive) session.alive = false;
  return alive;
}
