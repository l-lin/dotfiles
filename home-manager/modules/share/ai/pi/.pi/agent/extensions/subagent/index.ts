/**
 * Subagent Tool — spawn interactive pi instances in tmux split panes.
 *
 * The user sees and steers sub-agents directly. Results flow back via
 * file-based IPC + fs.watch that auto-triggers the main agent.
 */

import { StringEnum } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { type AgentConfig, type AgentScope, discoverAgents } from "./agents.js";
import { loadConfig } from "./config.js";
import * as render from "./render.js";
import * as sessions from "./sessions.js";
import * as tmux from "./tmux.js";
import type { SpawnResult, SubagentDetails } from "./types.js";

// ─── result helpers ──────────────────────────────────────────────────────────

type ToolResult = { content: { type: "text"; text: string }[]; isError?: boolean; details?: SubagentDetails };

const ok = (text: string, details?: SubagentDetails): ToolResult =>
  ({ content: [{ type: "text", text }], details });

const err = (text: string): ToolResult =>
  ({ content: [{ type: "text", text }], isError: true });

function requireSession(id: string | undefined): sessions.Session | ToolResult {
  if (!id) return err('Required parameter: "id".');
  const s = sessions.get(id);
  if (s) return s;
  return err(`Unknown session "${id}". Active: ${sessions.ids().join(", ") || "none"}`);
}

function isSession(v: sessions.Session | ToolResult): v is sessions.Session {
  return "paneId" in v;
}

function toSpawnResult(s: sessions.Session): SpawnResult {
  return { id: s.id, agent: s.agentName, agentSource: s.agentSource, paneId: s.paneId };
}

// ─── schema ──────────────────────────────────────────────────────────────────

const SubagentParams = Type.Object({
  action: StringEnum(["spawn", "send", "read", "close"] as const, {
    description: "Action: spawn, send, read, close",
  }),
  agent: Type.Optional(Type.String({ description: "Agent name (for spawn)" })),
  task: Type.Optional(Type.String({ description: "Task to delegate (for spawn)" })),
  tasks: Type.Optional(Type.Array(
    Type.Object({
      agent: Type.String({ description: "Name of the agent to invoke" }),
      task: Type.String({ description: "Task to delegate to the agent" }),
      cwd: Type.Optional(Type.String({ description: "Working directory for the agent process" })),
    }),
    { description: "Array of {agent, task} for parallel spawn" },
  )),
  id: Type.Optional(Type.String({ description: "Session ID (for send/read/close)" })),
  message: Type.Optional(Type.String({ description: "Message to send (for send)" })),
  agentScope: Type.Optional(StringEnum(["user", "project", "both"] as const, {
    description: 'Agent directories to use. Default: "user".', default: "user",
  })),
  confirmProjectAgents: Type.Optional(Type.Boolean({
    description: "Prompt before running project-local agents. Default: true.", default: true,
  })),
  cwd: Type.Optional(Type.String({ description: "Working directory for the agent process" })),
});

// ─── action handlers ─────────────────────────────────────────────────────────

function handleSend(params: any): ToolResult {
  if (!params.message) return err('Send requires "message" parameter.');
  const lookup = requireSession(params.id);
  if (!isSession(lookup)) return lookup;
  if (!sessions.checkAlive(lookup)) return err(`Sub-agent "${lookup.agentName}" (${lookup.id}) is no longer running.`);

  tmux.sendMessage(lookup.paneId, params.message);
  return ok(`Message sent to "${lookup.agentName}" (${lookup.id}).`, { action: "send", sessionId: lookup.id });
}

function handleRead(params: any): ToolResult {
  // No ID → list all sessions
  if (!params.id) {
    if (sessions.size() === 0) return ok("No active sub-agent sessions.");
    const summaries = sessions.all().map((s) => {
      return `**${s.agentName}** (${s.id})`;
    });
    return ok(summaries.join("\n\n"), { action: "read" });
  }

  const lookup = requireSession(params.id);
  if (!isSession(lookup)) return lookup;
  sessions.refreshResult(lookup);
  sessions.checkAlive(lookup);
  return ok(lookup.lastResult || "(no result yet)", { action: "read", sessionId: lookup.id, result: lookup.lastResult });
}

function handleClose(params: any): ToolResult {
  if (params.id === "all") {
    const count = sessions.size();
    sessions.closeAll();
    return ok(`Closed ${count} sub-agent session(s).`, { action: "close" });
  }
  const lookup = requireSession(params.id);
  if (!isSession(lookup)) return lookup;
  const lastResult = lookup.lastResult;
  sessions.close(lookup);
  return ok(
    `Closed "${lookup.agentName}" (${lookup.id}).${lastResult ? `\n\nFinal result:\n${lastResult}` : ""}`,
    { action: "close", sessionId: lookup.id },
  );
}

async function handleSpawn(
  pi: ExtensionAPI,
  params: any,
  ctx: any,
): Promise<ToolResult> {
  const config = loadConfig();
  const scope: AgentScope = params.agentScope ?? config.agentScope;
  const discovery = discoverAgents(ctx.cwd, scope);
  const agents = discovery.agents;
  const availableNames = agents.map((a) => `"${a.name}"`).join(", ") || "none";

  // Normalize: single → array
  const taskList: { agent: string; task: string; cwd?: string }[] =
    params.tasks?.length > 0
      ? params.tasks
      : params.agent && params.task
        ? [{ agent: params.agent, task: params.task, cwd: params.cwd }]
        : [];

  if (taskList.length === 0) return err(`Spawn requires agent+task or tasks array.\nAvailable agents: ${availableNames}`);
  if (taskList.length > config.maxParallel) return err(`Too many parallel tasks (${taskList.length}). Max is ${config.maxParallel}.`);

  // Confirm project agents if needed
  if ((scope === "project" || scope === "both") && (params.confirmProjectAgents ?? config.confirmProjectAgents) && ctx.hasUI) {
    const projectAgents = taskList
      .map((t) => agents.find((a) => a.name === t.agent))
      .filter((a): a is AgentConfig => a?.source === "project");

    if (projectAgents.length > 0) {
      const names = [...new Set(projectAgents.map((a) => a.name))].join(", ");
      const confirmed = await ctx.ui.confirm(
        "Run project-local agents?",
        `Agents: ${names}\nSource: ${discovery.projectAgentsDir ?? "(unknown)"}\n\nProject agents are repo-controlled. Only continue for trusted repositories.`,
      );
      if (!confirmed) return ok("Canceled: project-local agents not approved.");
    }
  }

  // Spawn all tasks
  const spawned: SpawnResult[] = [];
  for (const t of taskList) {
    const agent = agents.find((a) => a.name === t.agent);
    if (!agent) {
      const already = spawned.length > 0
        ? ` Already spawned: ${spawned.map((s) => `${s.agent} (${s.id})`).join(", ")}. Use close action to clean up.`
        : "";
      return { ...err(`Unknown agent: "${t.agent}". Available: ${availableNames}.${already}`), details: { action: "spawn", agentScope: scope, spawned } };
    }
    spawned.push(toSpawnResult(sessions.spawn(pi, agent, t.task, t.cwd ?? ctx.cwd)));
  }

  if (spawned.length > 1) tmux.rebalance();

  const lines = spawned.map((s) => `- **${s.agent}** → session \`${s.id}\``).join("\n");
  return ok(
    `Spawned ${spawned.length} sub-agent(s):\n${lines}\n\nResults delivered automatically. Use send/read/close with session IDs.`,
    { action: "spawn", agentScope: scope, spawned },
  );
}

// ─── extension ───────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  pi.on("session_shutdown", async () => sessions.closeAll());
  pi.on("session_switch", async () => sessions.closeAll());

  pi.registerMessageRenderer("subagent-result", render.renderMessage);

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Manage interactive sub-agents in tmux panes.",
      "",
      "Actions:",
      '  spawn  — Create pane(s). "agent"+"task" for single, "tasks" array for parallel.',
      '  send   — Send message to sub-agent. Requires "id" and "message".',
      '  read   — Read latest result. Requires "id" (omit for all).',
      '  close  — Kill pane. Requires "id" (or "all").',
      "",
      "Results are delivered automatically via file watcher.",
      "Requires tmux.",
    ].join("\n"),
    parameters: SubagentParams,

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      if (!tmux.isInsideTmux()) {
        return err("Subagent requires running inside tmux.");
      }
      switch (params.action) {
        case "send":  return handleSend(params);
        case "read":  return handleRead(params);
        case "close": return handleClose(params);
        case "spawn": return handleSpawn(pi, params, ctx);
        default:      return err(`Unknown action "${params.action}".`);
      }
    },

    renderCall: render.renderCall,
    renderResult: render.renderResult,
  });
}
