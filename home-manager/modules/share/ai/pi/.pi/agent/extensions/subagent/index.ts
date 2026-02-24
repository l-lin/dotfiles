/**
 * Subagent Tool — spawn interactive pi instances in tmux split panes.
 *
 * The user sees and steers sub-agents directly. Results flow back via
 * file-based IPC + fs.watch that auto-triggers the main agent.
 */

import { StringEnum } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ToolContext } from "@mariozechner/pi-coding-agent";
import { truncateToWidth } from "@mariozechner/pi-tui";
import { Type, type Static } from "@sinclair/typebox";
import { discoverAgents } from "./agents.js";
import { loadConfig } from "./config.js";
import * as render from "./render.js";
import * as sessions from "./sessions.js";
import { Action } from "./sessions.js";
import type { SpawnResult, SubagentDetails } from "./sessions.js";
import * as tmux from "./tmux.js";

// ─── result helpers ──────────────────────────────────────────────────────────

interface ToolResult {
  content: { type: "text"; text: string }[];
  isError?: boolean;
  details?: SubagentDetails;
}

const ok = (text: string, details?: SubagentDetails): ToolResult => ({
  content: [{ type: "text", text }],
  details,
});

const err = (text: string): ToolResult => ({
  content: [{ type: "text", text }],
  isError: true,
});

function getSession(id: string | undefined): sessions.Session | undefined {
  return id ? sessions.get(id) : undefined;
}

// ─── schema ──────────────────────────────────────────────────────────────────

const ACTIONS = [Action.Spawn, Action.Send, Action.Read, Action.Close] as const;

type SubagentParams = Static<typeof SubagentParamsSchema>;
const SubagentParamsSchema = Type.Object({
  action: StringEnum(ACTIONS, {
    description: "Action: spawn, send, read, close",
  }),
  agent: Type.Optional(Type.String({ description: "Agent name (for spawn)" })),
  task: Type.Optional(
    Type.String({ description: "Task to delegate (for spawn)" }),
  ),
  tasks: Type.Optional(
    Type.Array(
      Type.Object({
        agent: Type.String({ description: "Name of the agent to invoke" }),
        task: Type.String({ description: "Task to delegate to the agent" }),
        cwd: Type.Optional(
          Type.String({
            description: "Working directory for the agent process",
          }),
        ),
      }),
      { description: "Array of {agent, task} for parallel spawn" },
    ),
  ),
  id: Type.Optional(
    Type.String({ description: "Session ID (for send/read/close)" }),
  ),
  message: Type.Optional(
    Type.String({ description: "Message to send (for send)" }),
  ),
  sources: Type.Optional(
    Type.Array(Type.String(), {
      description:
        "Directories to search for agent definitions. Accepts absolute paths (~ and $HOME are expanded) or paths relative to cwd. Overrides config defaults.",
    }),
  ),
  cwd: Type.Optional(
    Type.String({ description: "Working directory for the agent process" }),
  ),
});

function sessionError(id: string | undefined): ToolResult {
  if (!id) return err('Required parameter: "id".');
  return err(
    `Unknown session "${id}". Active: ${sessions.ids().join(", ") || "none"}`,
  );
}

// ─── action handlers ─────────────────────────────────────────────────────────

function handleSend(params: SubagentParams): ToolResult {
  if (!params.message) return err('Send requires "message" parameter.');
  const session = getSession(params.id);
  if (!session) return sessionError(params.id);
  if (!sessions.checkAlive(session))
    return err(
      `Sub-agent "${session.agentName}" (${session.id}) is no longer running.`,
    );

  session.pending = true;
  tmux.sendMessage(session.paneId, params.message);
  return ok(`Message sent to "${session.agentName}" (${session.id}).`, {
    action: Action.Send,
    sessionId: session.id,
  });
}

const POLL_WARNING = `\
⛔ STOP — DO NOT PROCEED.

Subagents are still running. Results are pushed automatically — you will be \
notified the moment they finish. Polling wastes time and context.

DO NOT:
- Call subagent read again
- Do the subagents' work yourself
- Take any other action

Just stop and wait. Your turn will be triggered automatically.`;

function handleRead(params: SubagentParams): ToolResult {
  // No ID → list all sessions
  if (!params.id) {
    if (sessions.size() === 0) return ok("No active sub-agent sessions.");
    const pending = sessions.all().filter((s) => s.pending);
    if (pending.length > 0) {
      return err(POLL_WARNING);
    }
    const summaries = sessions.all().map((s) => `**${s.agentName}** (${s.id})`);
    return ok(summaries.join("\n\n"), { action: Action.Read });
  }

  const session = getSession(params.id);
  if (!session) return sessionError(params.id);
  sessions.refreshResult(session);
  sessions.checkAlive(session);

  if (session.pending) {
    return err(POLL_WARNING);
  }

  return ok(session.lastResult || "(no result yet)", {
    action: Action.Read,
    sessionId: session.id,
    result: session.lastResult,
  });
}

function handleClose(params: SubagentParams): ToolResult {
  if (params.id === "all") {
    const count = sessions.size();
    sessions.closeAll();
    return ok(`Closed ${count} sub-agent session(s).`, {
      action: Action.Close,
    });
  }
  const session = getSession(params.id);
  if (!session) return sessionError(params.id);
  sessions.close(session);
  return ok("", { action: Action.Close, sessionId: session.id });
}

async function handleSpawn(
  pi: ExtensionAPI,
  params: SubagentParams,
  ctx: ToolContext,
): Promise<ToolResult> {
  const config = loadConfig();
  const sources: string[] = params.sources ?? config.sources;
  const discovery = discoverAgents(sources, ctx.cwd);
  const agents = discovery.agents;
  const availableNames = agents.map((a) => `"${a.name}"`).join(", ") || "none";

  // Normalize: single → array
  const taskList: { agent: string; task: string; cwd?: string }[] =
    params.tasks?.length > 0
      ? params.tasks
      : params.agent && params.task
        ? [{ agent: params.agent, task: params.task, cwd: params.cwd }]
        : [];

  if (taskList.length === 0)
    return err(
      `Spawn requires agent+task or tasks array.\nAvailable agents: ${availableNames}`,
    );
  if (taskList.length > config.maxParallel)
    return err(
      `Too many parallel tasks (${taskList.length}). Max is ${config.maxParallel}.`,
    );

  // Spawn subagents one at a time
  const spawned: SpawnResult[] = [];
  let windowId: string | undefined;

  for (const t of taskList) {
    const agent = agents.find((a) => a.name === t.agent);
    if (!agent) {
      const already =
        spawned.length > 0
          ? ` Already spawned: ${spawned.map((s) => `${s.agent} (${s.id})`).join(", ")}. Use close action to clean up.`
          : "";
      return {
        ...err(
          `Unknown agent: "${t.agent}". Available: ${availableNames}.${already}`,
        ),
        details: { action: Action.Spawn, sources, spawned },
      };
    }
    const session = sessions.spawn(pi, agent, t.task, t.cwd ?? ctx.cwd);
    spawned.push({
      id: session.id,
      agent: session.agentName,
      agentSource: session.agentSource,
      paneId: session.paneId,
    });

    // Capture window ID from first spawn for rebalancing
    if (!windowId) {
      windowId = tmux.getWindowId(session.paneId);
    }
  }

  if (spawned.length > 1 && windowId) tmux.rebalance(windowId);

  sessions.registerGroup(spawned.map((s) => s.id));

  const lines = spawned
    .map((s) => `- **${s.agent}** → session \`${s.id}\``)
    .join("\n");
  return ok(
    `Spawned ${spawned.length} sub-agent(s):\n${lines}\n\n` +
      `⛔ STOP HERE. Do not call any tools. Do not do the work yourself. Do not poll with read.\n` +
      `Results are pushed automatically — your turn will be triggered once all sub-agents have reported.\n` +
      `Use send to send follow-up messages, close to terminate a session.`,
    { action: Action.Spawn, sources, spawned },
  );
}

// ─── session widget ──────────────────────────────────────────────────────────

const WIDGET_KEY = "subagent-sessions";
let blinkTimer: ReturnType<typeof setInterval> | undefined;

function stopBlinkTimer(): void {
  if (blinkTimer) {
    clearInterval(blinkTimer);
    blinkTimer = undefined;
  }
}

function updateSessionWidget(ctx: ToolContext): void {
  stopBlinkTimer();
  const active = sessions.all();

  if (active.length === 0) {
    ctx.ui.setWidget(WIDGET_KEY, undefined);
    return;
  }

  ctx.ui.setWidget(WIDGET_KEY, (tui, theme) => {
    // Blink timer: re-renders every 500ms while any session is pending
    blinkTimer = setInterval(() => {
      tui.requestRender();
      if (!sessions.all().some((s) => s.pending)) stopBlinkTimer();
    }, 500);

    return {
      render: (width: number) => {
        const blinkOn = Math.floor(Date.now() / 500) % 2 === 0;
        return active.map((s) => {
          const icon = s.pending
            ? blinkOn
              ? theme.fg("success", "󰚩")
              : " "
            : s.alive
              ? theme.fg("success", "󰚩")
              : theme.fg("muted", "󰚩");
          const id = theme.fg("toolTitle", theme.bold(s.id));
          const task = theme.fg(
            "dim",
            s.task.length > 50 ? `${s.task.slice(0, 50)}…` : s.task,
          );
          return truncateToWidth(`${icon} ${id} ${task}`, width);
        });
      },
      invalidate: () => {},
    };
  });
}

// ─── list-agents schema ──────────────────────────────────────────────────────

type ListAgentsParams = Static<typeof ListAgentsParamsSchema>;
const ListAgentsParamsSchema = Type.Object({});

// ─── extension ───────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  pi.on("session_shutdown", async () => {
    stopBlinkTimer();
    sessions.closeAll();
  });
  pi.on("session_switch", async (_event, ctx) => {
    stopBlinkTimer();
    sessions.closeAll();
    ctx.ui.setWidget(WIDGET_KEY, undefined);
  });
  pi.on("session_start", async (_event, ctx) =>
    ctx.ui.setWidget(WIDGET_KEY, undefined),
  );

  pi.registerMessageRenderer("subagent-result", render.renderMessage);

  pi.registerTool({
    name: "list-subagents",
    label: "List Subagents",
    description:
      "List all available subagents (name and description) to determine which agent to spawn for a given task.",
    parameters: ListAgentsParamsSchema,

    async execute(
      _toolCallId,
      _params: ListAgentsParams,
      _signal,
      _onUpdate,
      ctx,
    ) {
      const config = loadConfig();
      const sources: string[] = config.sources;
      const discovery = discoverAgents(sources, ctx.cwd);
      const agents = discovery.agents;

      if (agents.length === 0) {
        return ok(
          "No subagents found. Check your configuration or agent directories.",
        );
      }

      const lines = agents.map((a) => `**${a.name}**\n  ${a.description}`);
      return ok(`Available subagents:\n\n${lines.join("\n\n")}`, {
        action: Action.List,
        count: agents.length,
      });
    },

    renderCall: render.renderListCall,
    renderResult: render.renderListResult,
  });

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Manage interactive sub-agents in tmux panes.",
      "",
      "Actions:",
      '  spawn  — Create pane(s). "agent"+"task" for single, "tasks" array for parallel.',
      '  send   — Send message to sub-agent. Requires "id" and "message".',
      '  read   — Read latest result. Requires "id" (omit for all). NEVER poll with this after spawn — if subagents are still running, this returns an error. Results are pushed automatically.',
      '  close  — Kill pane. Requires "id" (or "all").',
      "",
      "IMPORTANT: After spawning, STOP — do not call any tools, do not do the work yourself. If you call read while agents are running, you get an error. Results are pushed automatically via file watcher; your turn is triggered once all sub-agents have reported.",
      "Requires tmux.",
    ].join("\n"),
    parameters: SubagentParamsSchema,

    async execute(
      _toolCallId,
      params: SubagentParams,
      _signal,
      _onUpdate,
      ctx,
    ) {
      if (!tmux.isInsideTmux()) {
        return err("Subagent requires running inside tmux.");
      }
      let result: ToolResult;
      switch (params.action) {
        case Action.Send:
          result = handleSend(params);
          break;
        case Action.Read:
          result = handleRead(params);
          break;
        case Action.Close:
          result = handleClose(params);
          break;
        case Action.Spawn:
          result = await handleSpawn(pi, params, ctx);
          break;
        default:
          return err(`Unknown action "${params.action}".`);
      }
      if (params.action !== Action.Read) updateSessionWidget(ctx);
      return result;
    },

    renderCall: render.renderCall,
    renderResult: render.renderResult,
  });
}
