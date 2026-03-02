/**
 * Subagent Tool — spawn interactive pi instances in tmux split panes.
 *
 * The user sees and steers subagents directly. Results flow back via
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

const ACTIONS = [
  Action.Spawn,
  Action.Send,
  Action.Close,
  Action.Catalog,
  Action.List,
] as const;

type SubagentParams = Static<typeof SubagentParamsSchema>;
const SubagentParamsSchema = Type.Object({
  action: StringEnum(ACTIONS, {
    description: "Action: spawn, send, close, catalog, list",
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

function handleCatalog(params: SubagentParams, ctx: ToolContext): ToolResult {
  const config = loadConfig();
  const sources: string[] = params.sources ?? config.sources;
  const discovery = discoverAgents(sources, ctx.cwd);
  const agents = discovery.agents;

  if (agents.length === 0) {
    return ok(
      "No subagents found. Check your configuration or agent directories.",
    );
  }

  const lines = agents.map((a) => `**${a.name}**\n  ${a.description}`);
  return ok(`Available subagents:\n\n${lines.join("\n\n")}`, {
    action: Action.Catalog,
    count: agents.length,
  });
}

function handleList(): ToolResult {
  const active = sessions.all();
  if (active.length === 0) {
    return ok("No active subagent sessions.", {
      action: Action.List,
      count: 0,
    });
  }
  const lines = active.map((s) => {
    const status = s.pending
      ? " pending"
      : s.lastResult
        ? " result ready"
        : s.alive
          ? "󰚩 running"
          : "󱚧 stopped";
    const task = s.task.length > 60 ? `${s.task.slice(0, 60)}…` : s.task;
    return `**${s.id}** (${s.agentName}) — ${status}\n  Task: ${task}`;
  });
  return ok(`Active subagents (${active.length}):\n\n${lines.join("\n\n")}`, {
    action: Action.List,
    count: active.length,
  });
}

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
      `Subagent "${session.agentName}" (${session.id}) is no longer running.`,
    );

  session.pending = true;
  tmux.sendMessage(session.paneId, params.message);
  return ok(`Message sent to "${session.agentName}" (${session.id}).`, {
    action: Action.Send,
    sessionId: session.id,
  });
}

function handleClose(params: SubagentParams): ToolResult {
  if (params.id === "all") {
    const count = sessions.size();
    sessions.closeAll();
    return ok(`Closed ${count} subagent(s).`, {
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
    (params.tasks?.length ?? 0) > 0
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
  }

  sessions.registerGroup(spawned.map((s) => s.id));

  const lines = spawned
    .map((s) => `- **${s.agent}** → session \`${s.id}\``)
    .join("\n");
  return ok(
    `Spawned ${spawned.length} subagent(s):\n${lines}\n\n` +
      `Results will be injected into context when all the subagents have finished their task.\n` +
      `Use send to send follow-up messages, close to terminate a subagent.`,
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

  // Start the blink timer here (outside the factory) so it is only created
  // once per widget registration.  The factory is a pure render function and
  // must NOT start timers — it may be called on every resize / theme-change /
  // requestRender(), which would leak timers and cause repeated re-renders.
  let requestRenderFn: (() => void) | undefined;
  blinkTimer = setInterval(() => {
    requestRenderFn?.();
    if (!sessions.all().some((s) => s.pending)) stopBlinkTimer();
  }, 500);

  ctx.ui.setWidget(WIDGET_KEY, (tui, theme) => {
    // Capture the tui.requestRender handle so the timer above can use it.
    requestRenderFn = () => tui.requestRender();

    return {
      render: (width: number) => {
        const blinkOn = Math.floor(Date.now() / 500) % 2 === 0;
        return sessions.all().map((s) => {
          // live snapshot — not stale closure
          const hasResult = s.lastResult.length > 0;
          const icon = s.pending
            ? blinkOn
              ? theme.fg("success", "󰚩")
              : " "
            : hasResult
              ? theme.fg("accent", "󰚩") // result ready — read via subagent-read
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

  pi.registerCommand("cmd:subagent-close", {
    description: "Interactively close one or all active subagents",

    handler: async (_args, ctx) => {
      const active = sessions.all();
      if (active.length === 0) {
        ctx.ui.notify("No active subagent.", "info");
        return;
      }

      const ALL_LABEL = "󰚩 ALL";
      const options = [ALL_LABEL, ...active.map((s) => `󰚩 ${s.id}`)];
      const chosen = await ctx.ui.select(
        "Select a subagent to close:",
        options,
      );
      if (!chosen) return;

      if (chosen === ALL_LABEL) {
        const count = sessions.size();
        sessions.closeAll();
        updateSessionWidget(ctx);
        ctx.ui.notify(`Closed all ${count} subagent(s).`, "info");
      } else {
        const id = chosen.slice(chosen.indexOf(" ") + 1);
        const session = sessions.get(id);
        if (!session) {
          ctx.ui.notify(`Subagent "${id}" not found.`, "error");
          return;
        }
        sessions.close(session);
        updateSessionWidget(ctx);
        ctx.ui.notify(`Closed subagent "${id}".`, "info");
      }
    },
  });

  pi.registerCommand("cmd:subagent-read", {
    description:
      "Read result(s) from finished subagents and inject into agent context",

    handler: async (_args, ctx) => {
      const active = sessions.all();
      if (active.length === 0) {
        ctx.ui.notify("No active subagent sessions.", "info");
        return;
      }

      for (const s of active) sessions.refreshResult(s);
      const finished = active.filter((s) => s.lastResult.length > 0);

      if (finished.length === 0) {
        ctx.ui.notify("No subagent has reported a result yet.", "warning");
        return;
      }

      const ALL_LABEL = "󰚩 ALL";
      const options = [ALL_LABEL, ...finished.map((s) => `󰚩 ${s.id}`)];
      const chosen = await ctx.ui.select("Read result from:", options);
      if (!chosen) return;

      const targets =
        chosen === ALL_LABEL
          ? finished
          : (() => {
              const id = chosen.slice(chosen.indexOf(" ") + 1);
              const s = sessions.get(id);
              return s ? [s] : [];
            })();

      if (targets.length === 0) {
        ctx.ui.notify("Session not found.", "error");
        return;
      }

      const parts = targets.map(
        (s) =>
          `### Result from subagent \`${s.id}\` (${s.agentName})\n\n${s.lastResult}`,
      );
      const combined = parts.join("\n\n---\n\n");

      try {
        pi.sendMessage(
          {
            customType: "subagent-result",
            content: combined,
            display: true,
            details: {
              action: Action.Read,
              sessionId: targets.length === 1 ? targets[0].id : "all",
            },
          },
          { triggerTurn: true, deliverAs: "followUp" },
        );
      } catch (e: any) {
        ctx.ui.notify(`Failed to inject result: ${e?.message ?? e}`, "error");
        return;
      }

      const label =
        targets.length === 1
          ? `"${targets[0].id}"`
          : `${targets.length} subagents`;
      ctx.ui.notify(`Injected result from ${label} into context.`, "info");
    },
  });

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Manage interactive subagents in tmux windows.",
      "",
      "Actions:",
      "  catalog — List all available agent definitions (name and description) to determine which agent to spawn.",
      "  list   — List all active subagent sessions with their status (running/pending/result ready).",
      '  spawn  — Create window(s). "agent"+"task" for single, "tasks" array for parallel.',
      '  send   — Send message to subagent. Requires "id" and "message".',
      '  close  — Kill window. Requires "id" (or "all").',
      "",
      "IMPORTANT: After spawning, STOP — do not call any tools, do not do the work yourself. Results are delivered by the user via the subagent-read command. Your turn is triggered once the user reads a result.",
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
      if (params.action === Action.Catalog) return handleCatalog(params, ctx);
      if (params.action === Action.List) return handleList();
      if (!tmux.isInsideTmux()) {
        return err("Subagent requires running inside tmux.");
      }
      let result: ToolResult;
      switch (params.action) {
        case Action.Send:
          result = handleSend(params);
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
      updateSessionWidget(ctx);
      return result;
    },

    renderCall: (args: any, theme: any) => {
      switch (args.action) {
        case Action.Catalog:
          return render.renderCatalogCall(args, theme);
        case Action.List:
          return render.renderListCall(args, theme);
        case Action.Spawn:
          return render.renderSpawnCall(args, theme);
        case Action.Send:
          return render.renderSendCall(args, theme);
        case Action.Close:
          return render.renderCloseCall(args, theme);
        default:
          return render.renderCatalogCall(args, theme);
      }
    },
    renderResult: (result: any, opts: any, theme: any) => {
      switch (result.details?.action) {
        case Action.Catalog:
          return render.renderCatalogResult(result, opts, theme);
        case Action.List:
          return render.renderListResult(result, opts, theme);
        default:
          return render.renderResult(result, opts, theme);
      }
    },
  });
}
