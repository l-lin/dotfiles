/**
 * Subagent Tool - Interactive sub-agents in tmux panes
 *
 * Spawns interactive `pi` instances in tmux split panes. The user can see
 * and steer sub-agents directly. Results are communicated back via file-based
 * IPC + fs.watch notifications that auto-trigger the main agent.
 *
 * Actions:
 *   - spawn:  Create a sub-agent in a new tmux pane (single or parallel)
 *   - send:   Send a message to a running sub-agent (via tmux send-keys)
 *   - read:   Read the latest result from a sub-agent
 *   - close:  Kill a sub-agent's pane and clean up
 *
 * Requires the main agent to be running inside tmux.
 */

import { execSync } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { StringEnum } from "@mariozechner/pi-ai";
import {
  type ExtensionAPI,
  getMarkdownTheme,
} from "@mariozechner/pi-coding-agent";
import { Container, Markdown, Spacer, Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";
import { type AgentConfig, type AgentScope, discoverAgents } from "./agents.js";

const MAX_PARALLEL_TASKS = 4;

// ─── session state ───────────────────────────────────────────────────────────

interface SubagentSession {
  id: string;
  agentName: string;
  agentSource: "user" | "project";
  task: string;
  paneId: string;
  resultFile: string;
  cwd: string;
  watcher?: fs.FSWatcher;
  lastResult: string;
  systemPromptFile?: string;
  alive: boolean;
}

const sessions = new Map<string, SubagentSession>();

function generateSessionId(agentName: string): string {
  const safe = agentName.replace(/[^\w]/g, "").slice(0, 12);
  const rand = Math.random().toString(36).slice(2, 6);
  return `${safe}-${rand}`;
}

// ─── tmux helpers ────────────────────────────────────────────────────────────

function isInsideTmux(): boolean {
  return !!process.env.TMUX;
}

function shellEscape(s: string): string {
  return `'${s.replace(/'/g, "'\\''")}'`;
}

/** Split the current pane horizontally (new pane on the right), returns pane ID */
function tmuxSplitRight(cwd: string): string {
  return execSync(
    `tmux split-window -h -d -P -F '#{pane_id}' -c ${shellEscape(cwd)}`,
    { encoding: "utf-8" },
  ).trim();
}

/** Send literal text to a pane, then press Enter */
function tmuxSendMessage(paneId: string, text: string): void {
  execSync(`tmux send-keys -t ${shellEscape(paneId)} -l ${shellEscape(text)}`);
  execSync(`tmux send-keys -t ${shellEscape(paneId)} Enter`);
}

/** Send a raw command string to a pane (keys are interpreted) */
function tmuxSendKeys(paneId: string, text: string): void {
  execSync(`tmux send-keys -t ${shellEscape(paneId)} ${shellEscape(text)} C-m`);
}

/** Kill a tmux pane */
function tmuxKillPane(paneId: string): void {
  try {
    execSync(`tmux kill-pane -t ${shellEscape(paneId)}`, { stdio: "ignore" });
  } catch {
    // pane may already be dead
  }
}

/** Check if a tmux pane is still alive */
function tmuxPaneAlive(paneId: string): boolean {
  try {
    execSync(`tmux has-session -t ${shellEscape(paneId)}`, {
      stdio: "ignore",
    });
    return true;
  } catch {
    return false;
  }
}

/** Rebalance pane layout */
function tmuxEvenHorizontal(): void {
  try {
    execSync("tmux select-layout even-horizontal", { stdio: "ignore" });
  } catch {
    // ignore
  }
}

// ─── temp file helpers ───────────────────────────────────────────────────────

function createSessionDir(sessionId: string): string {
  const dir = path.join(os.tmpdir(), `pi-subagent-${sessionId}`);
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}

function writePromptToTempFile(
  dir: string,
  agentName: string,
  prompt: string,
): string {
  const safeName = agentName.replace(/[^\w.-]+/g, "_");
  const filePath = path.join(dir, `prompt-${safeName}.md`);
  fs.writeFileSync(filePath, prompt, { encoding: "utf-8", mode: 0o600 });
  return filePath;
}

function cleanupSessionDir(sessionId: string): void {
  const dir = path.join(os.tmpdir(), `pi-subagent-${sessionId}`);
  try {
    fs.rmSync(dir, { recursive: true, force: true });
  } catch {
    // ignore
  }
}

// ─── build pi command ────────────────────────────────────────────────────────

function buildPiCommand(
  agent: AgentConfig,
  task: string,
  resultFile: string,
  systemPromptFile?: string,
): string {
  const parts: string[] = ["pi"];

  if (agent.model) {
    parts.push("--model", shellEscape(agent.model));
  }

  // Ensure 'write' is in tools so sub-agent can write the result file
  const tools = agent.tools ? [...agent.tools] : undefined;
  if (tools && !tools.includes("write")) {
    tools.push("write");
  }
  if (tools && tools.length > 0) {
    parts.push("--tools", shellEscape(tools.join(",")));
  }

  if (systemPromptFile) {
    parts.push("--append-system-prompt", shellEscape(systemPromptFile));
  }
  parts.push("--no-session");

  const augmentedTask = `${task}

IMPORTANT COMMUNICATION PROTOCOL:
When you have completed the task (or have a meaningful intermediate result to report), write your answer/summary to "${resultFile}" using the write tool. This file is monitored by the parent agent — writing to it automatically notifies them. You can update this file multiple times as you make progress. Always do a final write before you finish.`;

  parts.push(shellEscape(`Task: ${augmentedTask}`));

  return parts.join(" ");
}

// ─── spawn a sub-agent ───────────────────────────────────────────────────────

function spawnSubagent(
  pi: ExtensionAPI,
  agent: AgentConfig,
  task: string,
  cwd: string,
): SubagentSession {
  const id = generateSessionId(agent.name);
  const sessionDir = createSessionDir(id);
  const resultFile = path.join(sessionDir, "result.md");

  let systemPromptFile: string | undefined;
  if (agent.systemPrompt.trim()) {
    systemPromptFile = writePromptToTempFile(
      sessionDir,
      agent.name,
      agent.systemPrompt,
    );
  }

  // Create the pane (doesn't steal focus thanks to -d flag)
  const paneId = tmuxSplitRight(cwd);

  // Build and send the pi command
  const piCmd = buildPiCommand(agent, task, resultFile, systemPromptFile);
  tmuxSendKeys(paneId, piCmd);

  const session: SubagentSession = {
    id,
    agentName: agent.name,
    agentSource: agent.source,
    task,
    paneId,
    resultFile,
    cwd,
    lastResult: "",
    systemPromptFile,
    alive: true,
  };

  // Watch the result file for changes
  // We watch the directory since the file doesn't exist yet
  try {
    session.watcher = fs.watch(sessionDir, (eventType, filename) => {
      if (filename !== "result.md") return;

      let content: string;
      try {
        content = fs.readFileSync(resultFile, "utf-8").trim();
      } catch {
        return;
      }

      if (!content || content === session.lastResult) return;
      session.lastResult = content;

      // Notify the main agent
      pi.sendMessage(
        {
          customType: "subagent-result",
          content: `Sub-agent "${agent.name}" (${id}) reported:\n\n${content}`,
          display: true,
          details: { sessionId: id, agentName: agent.name },
        },
        { triggerTurn: true, deliverAs: "followUp" },
      );
    });
  } catch {
    // If watching fails, agent can still use explicit read
  }

  sessions.set(id, session);
  return session;
}

// ─── cleanup a session ───────────────────────────────────────────────────────

function closeSession(session: SubagentSession): void {
  session.alive = false;
  session.watcher?.close();
  tmuxKillPane(session.paneId);
  cleanupSessionDir(session.id);
  sessions.delete(session.id);
}

// ─── schema ──────────────────────────────────────────────────────────────────

const TaskItem = Type.Object({
  agent: Type.String({ description: "Name of the agent to invoke" }),
  task: Type.String({ description: "Task to delegate to the agent" }),
  cwd: Type.Optional(
    Type.String({ description: "Working directory for the agent process" }),
  ),
});

const AgentScopeSchema = StringEnum(["user", "project", "both"] as const, {
  description:
    'Which agent directories to use. Default: "user". Use "both" to include project-local agents.',
  default: "user",
});

const ActionSchema = StringEnum(
  ["spawn", "send", "read", "close"] as const,
  {
    description:
      "Action to perform: spawn (create sub-agent), send (message to sub-agent), read (get result), close (kill pane)",
  },
);

const SubagentParams = Type.Object({
  action: ActionSchema,

  // For spawn (single)
  agent: Type.Optional(
    Type.String({ description: "Agent name (for spawn single mode)" }),
  ),
  task: Type.Optional(
    Type.String({ description: "Task to delegate (for spawn single mode)" }),
  ),

  // For spawn (parallel)
  tasks: Type.Optional(
    Type.Array(TaskItem, {
      description:
        "Array of {agent, task} for spawning multiple sub-agents in parallel panes",
    }),
  ),

  // For send
  id: Type.Optional(
    Type.String({
      description: "Session ID of the sub-agent (for send/read/close)",
    }),
  ),
  message: Type.Optional(
    Type.String({
      description: "Message to send to the sub-agent (for send action)",
    }),
  ),

  // Common
  agentScope: Type.Optional(AgentScopeSchema),
  confirmProjectAgents: Type.Optional(
    Type.Boolean({
      description: "Prompt before running project-local agents. Default: true.",
      default: true,
    }),
  ),
  cwd: Type.Optional(
    Type.String({ description: "Working directory for the agent process" }),
  ),
});

// ─── result types ────────────────────────────────────────────────────────────

interface SpawnResult {
  id: string;
  agent: string;
  agentSource: "user" | "project";
  paneId: string;
}

interface SubagentDetails {
  action: string;
  agentScope?: AgentScope;
  spawned?: SpawnResult[];
  sessionId?: string;
  result?: string;
}

// ─── extension ───────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  // Clean up all sessions on shutdown
  pi.on("session_shutdown", async () => {
    for (const session of sessions.values()) {
      closeSession(session);
    }
  });

  // Register custom message renderer for sub-agent notifications
  pi.registerMessageRenderer("subagent-result", (message, { expanded }, theme) => {
    const details = message.details as
      | { sessionId: string; agentName: string }
      | undefined;
    const name = details?.agentName ?? "sub-agent";
    const id = details?.sessionId ?? "?";
    const mdTheme = getMarkdownTheme();

    const icon = theme.fg("accent", "📨");
    const header = `${icon} ${theme.fg("toolTitle", theme.bold(name))} ${theme.fg("muted", `(${id})`)}`;

    if (expanded) {
      const container = new Container();
      container.addChild(new Text(header, 0, 0));
      container.addChild(new Spacer(1));
      container.addChild(
        new Markdown(message.content?.trim() ?? "(empty)", 0, 0, mdTheme),
      );
      return container;
    }

    const content = message.content ?? "";
    const preview = content.split("\n").slice(0, 5).join("\n");
    let text = header;
    text += `\n${theme.fg("toolOutput", preview)}`;
    if (content.split("\n").length > 5) {
      text += `\n${theme.fg("muted", "(Ctrl+O to expand)")}`;
    }
    return new Text(text, 0, 0);
  });

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Manage interactive sub-agents in tmux panes. The user can see and steer them.",
      "",
      "Actions:",
      '  spawn  - Create sub-agent pane(s). Use "agent"+"task" for single, or "tasks" array for parallel.',
      "           Returns session ID(s). The sub-agent runs interactively — you don't need to wait.",
      '  send   - Send a message to a running sub-agent. Requires "id" and "message".',
      '  read   - Read the latest result from a sub-agent. Requires "id".',
      '  close  - Kill a sub-agent pane and clean up. Requires "id". Use "all" to close all.',
      "",
      "Results are delivered automatically via file watcher notifications.",
      "Requires running inside tmux.",
    ].join("\n"),
    parameters: SubagentParams,

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      // ── tmux check ──
      if (!isInsideTmux()) {
        return {
          content: [
            {
              type: "text",
              text: "Subagent requires running inside tmux. Start pi inside a tmux session to use sub-agents.",
            },
          ],
          isError: true,
        };
      }

      const action = params.action;

      // ── SEND action ──
      if (action === "send") {
        if (!params.id || !params.message) {
          return {
            content: [
              {
                type: "text",
                text: 'Send requires "id" and "message" parameters.',
              },
            ],
            isError: true,
          };
        }

        const session = sessions.get(params.id);
        if (!session) {
          const active = Array.from(sessions.keys()).join(", ") || "none";
          return {
            content: [
              {
                type: "text",
                text: `Unknown session "${params.id}". Active sessions: ${active}`,
              },
            ],
            isError: true,
          };
        }

        if (!session.alive || !tmuxPaneAlive(session.paneId)) {
          session.alive = false;
          return {
            content: [
              {
                type: "text",
                text: `Sub-agent "${session.agentName}" (${session.id}) is no longer running.`,
              },
            ],
            isError: true,
          };
        }

        tmuxSendMessage(session.paneId, params.message);

        return {
          content: [
            {
              type: "text",
              text: `Message sent to "${session.agentName}" (${session.id}).`,
            },
          ],
          details: { action: "send", sessionId: session.id } as SubagentDetails,
        };
      }

      // ── READ action ──
      if (action === "read") {
        if (!params.id) {
          // List all sessions and their latest results
          if (sessions.size === 0) {
            return {
              content: [{ type: "text", text: "No active sub-agent sessions." }],
            };
          }

          const summaries = Array.from(sessions.values()).map((s) => {
            const alive = s.alive && tmuxPaneAlive(s.paneId);
            const status = alive ? "🟢 running" : "⚫ stopped";
            const result = s.lastResult
              ? `\n${s.lastResult.slice(0, 200)}${s.lastResult.length > 200 ? "..." : ""}`
              : "\n(no result yet)";
            return `**${s.agentName}** (${s.id}) ${status}${result}`;
          });

          return {
            content: [{ type: "text", text: summaries.join("\n\n") }],
            details: { action: "read" } as SubagentDetails,
          };
        }

        const session = sessions.get(params.id);
        if (!session) {
          const active = Array.from(sessions.keys()).join(", ") || "none";
          return {
            content: [
              {
                type: "text",
                text: `Unknown session "${params.id}". Active sessions: ${active}`,
              },
            ],
            isError: true,
          };
        }

        // Re-read the file in case watcher missed an update
        try {
          const content = fs.readFileSync(session.resultFile, "utf-8").trim();
          if (content) session.lastResult = content;
        } catch {
          // file may not exist yet
        }

        const alive = session.alive && tmuxPaneAlive(session.paneId);
        if (!alive) session.alive = false;

        return {
          content: [
            {
              type: "text",
              text: session.lastResult || "(no result yet)",
            },
          ],
          details: {
            action: "read",
            sessionId: session.id,
            result: session.lastResult,
          } as SubagentDetails,
        };
      }

      // ── CLOSE action ──
      if (action === "close") {
        if (params.id === "all") {
          const count = sessions.size;
          for (const session of sessions.values()) {
            closeSession(session);
          }
          return {
            content: [
              { type: "text", text: `Closed ${count} sub-agent session(s).` },
            ],
            details: { action: "close" } as SubagentDetails,
          };
        }

        if (!params.id) {
          return {
            content: [
              {
                type: "text",
                text: 'Close requires "id" parameter. Use "all" to close all sessions.',
              },
            ],
            isError: true,
          };
        }

        const session = sessions.get(params.id);
        if (!session) {
          const active = Array.from(sessions.keys()).join(", ") || "none";
          return {
            content: [
              {
                type: "text",
                text: `Unknown session "${params.id}". Active sessions: ${active}`,
              },
            ],
            isError: true,
          };
        }

        const lastResult = session.lastResult;
        closeSession(session);

        return {
          content: [
            {
              type: "text",
              text: `Closed "${session.agentName}" (${session.id}).${lastResult ? `\n\nFinal result:\n${lastResult}` : ""}`,
            },
          ],
          details: { action: "close", sessionId: session.id } as SubagentDetails,
        };
      }

      // ── SPAWN action ──
      if (action !== "spawn") {
        return {
          content: [
            {
              type: "text",
              text: `Unknown action "${action}". Use: spawn, send, read, close.`,
            },
          ],
          isError: true,
        };
      }

      const agentScope: AgentScope = params.agentScope ?? "user";
      const discovery = discoverAgents(ctx.cwd, agentScope);
      const agents = discovery.agents;
      const confirmProjectAgents = params.confirmProjectAgents ?? true;

      const hasTasks = (params.tasks?.length ?? 0) > 0;
      const hasSingle = Boolean(params.agent && params.task);

      if (!hasTasks && !hasSingle) {
        const available =
          agents.map((a) => `${a.name} (${a.source})`).join(", ") || "none";
        return {
          content: [
            {
              type: "text",
              text: `Spawn requires agent+task or tasks array.\nAvailable agents: ${available}`,
            },
          ],
          isError: true,
        };
      }

      // ── project agent confirmation ──
      if (
        (agentScope === "project" || agentScope === "both") &&
        confirmProjectAgents &&
        ctx.hasUI
      ) {
        const requestedNames = new Set<string>();
        if (params.tasks)
          for (const t of params.tasks) requestedNames.add(t.agent);
        if (params.agent) requestedNames.add(params.agent);

        const projectAgentsRequested = Array.from(requestedNames)
          .map((name) => agents.find((a) => a.name === name))
          .filter((a): a is AgentConfig => a?.source === "project");

        if (projectAgentsRequested.length > 0) {
          const names = projectAgentsRequested.map((a) => a.name).join(", ");
          const dir = discovery.projectAgentsDir ?? "(unknown)";
          const ok = await ctx.ui.confirm(
            "Run project-local agents?",
            `Agents: ${names}\nSource: ${dir}\n\nProject agents are repo-controlled. Only continue for trusted repositories.`,
          );
          if (!ok)
            return {
              content: [
                {
                  type: "text",
                  text: "Canceled: project-local agents not approved.",
                },
              ],
            };
        }
      }

      // ── spawn parallel ──
      if (params.tasks && params.tasks.length > 0) {
        if (params.tasks.length > MAX_PARALLEL_TASKS) {
          return {
            content: [
              {
                type: "text",
                text: `Too many parallel tasks (${params.tasks.length}). Max is ${MAX_PARALLEL_TASKS}.`,
              },
            ],
            isError: true,
          };
        }

        const spawned: SpawnResult[] = [];

        for (const t of params.tasks) {
          const agent = agents.find((a) => a.name === t.agent);
          if (!agent) {
            const available =
              agents.map((a) => `"${a.name}"`).join(", ") || "none";
            return {
              content: [
                {
                  type: "text",
                  text: `Unknown agent: "${t.agent}". Available: ${available}. Already spawned ${spawned.length} before error.`,
                },
              ],
              isError: true,
            };
          }

          const session = spawnSubagent(pi, agent, t.task, t.cwd ?? ctx.cwd);
          spawned.push({
            id: session.id,
            agent: session.agentName,
            agentSource: session.agentSource,
            paneId: session.paneId,
          });
        }

        tmuxEvenHorizontal();

        const lines = spawned
          .map((s) => `- **${s.agent}** → session \`${s.id}\``)
          .join("\n");

        return {
          content: [
            {
              type: "text",
              text: `Spawned ${spawned.length} sub-agents in tmux panes:\n${lines}\n\nResults will be delivered automatically when ready. Use send/read/close with session IDs to interact.`,
            },
          ],
          details: {
            action: "spawn",
            agentScope,
            spawned,
          } as SubagentDetails,
        };
      }

      // ── spawn single ──
      const agent = agents.find((a) => a.name === params.agent);
      if (!agent) {
        const available =
          agents.map((a) => `"${a.name}"`).join(", ") || "none";
        return {
          content: [
            {
              type: "text",
              text: `Unknown agent: "${params.agent}". Available: ${available}.`,
            },
          ],
          isError: true,
        };
      }

      const session = spawnSubagent(
        pi,
        agent,
        params.task!,
        params.cwd ?? ctx.cwd,
      );

      return {
        content: [
          {
            type: "text",
            text: `Spawned "${session.agentName}" in tmux pane → session \`${session.id}\`\n\nThe sub-agent is working on the task. Results will be delivered automatically when ready. The user can also interact with the sub-agent directly in the tmux pane.\n\nUse send/read/close with id "${session.id}" to interact.`,
          },
        ],
        details: {
          action: "spawn",
          agentScope,
          spawned: [
            {
              id: session.id,
              agent: session.agentName,
              agentSource: session.agentSource,
              paneId: session.paneId,
            },
          ],
        } as SubagentDetails,
      };
    },

    renderCall(args, theme) {
      const action = args.action || "?";

      switch (action) {
        case "spawn": {
          if (args.tasks && args.tasks.length > 0) {
            let text =
              theme.fg("toolTitle", theme.bold("subagent spawn ")) +
              theme.fg("accent", `${args.tasks.length} panes`);
            for (const t of args.tasks.slice(0, 3)) {
              const preview =
                t.task.length > 40 ? `${t.task.slice(0, 40)}...` : t.task;
              text += `\n  ${theme.fg("accent", t.agent)}${theme.fg("dim", ` ${preview}`)}`;
            }
            if (args.tasks.length > 3)
              text += `\n  ${theme.fg("muted", `... +${args.tasks.length - 3} more`)}`;
            return new Text(text, 0, 0);
          }
          const agentName = args.agent || "...";
          const preview = args.task
            ? args.task.length > 60
              ? `${args.task.slice(0, 60)}...`
              : args.task
            : "...";
          let text =
            theme.fg("toolTitle", theme.bold("subagent spawn ")) +
            theme.fg("accent", agentName);
          text += `\n  ${theme.fg("dim", preview)}`;
          return new Text(text, 0, 0);
        }

        case "send": {
          const id = args.id || "?";
          const msg = args.message || "...";
          const preview = msg.length > 50 ? `${msg.slice(0, 50)}...` : msg;
          return new Text(
            theme.fg("toolTitle", theme.bold("subagent send ")) +
              theme.fg("accent", id) +
              `\n  ${theme.fg("dim", preview)}`,
            0,
            0,
          );
        }

        case "read": {
          const id = args.id || "(all)";
          return new Text(
            theme.fg("toolTitle", theme.bold("subagent read ")) +
              theme.fg("accent", id),
            0,
            0,
          );
        }

        case "close": {
          const id = args.id || "?";
          return new Text(
            theme.fg("toolTitle", theme.bold("subagent close ")) +
              theme.fg("accent", id),
            0,
            0,
          );
        }

        default:
          return new Text(
            theme.fg("toolTitle", theme.bold("subagent ")) +
              theme.fg("dim", action),
            0,
            0,
          );
      }
    },

    renderResult(result, { expanded }, theme) {
      const details = result.details as SubagentDetails | undefined;
      const mdTheme = getMarkdownTheme();

      if (!details) {
        const text = result.content[0];
        return new Text(
          text?.type === "text" ? text.text : "(no output)",
          0,
          0,
        );
      }

      // For spawn, show session IDs prominently
      if (details.action === "spawn" && details.spawned?.length) {
        const container = new Container();

        for (const s of details.spawned) {
          const icon = theme.fg("success", "▶");
          container.addChild(
            new Text(
              `${icon} ${theme.fg("toolTitle", theme.bold(s.agent))} ${theme.fg("muted", `(${s.agentSource})`)} → ${theme.fg("accent", s.id)}`,
              0,
              0,
            ),
          );
        }

        if (expanded) {
          const content = result.content[0];
          if (content?.type === "text") {
            container.addChild(new Spacer(1));
            container.addChild(
              new Markdown(content.text.trim(), 0, 0, mdTheme),
            );
          }
        }

        return container;
      }

      // Default: render content as markdown if expanded, text if collapsed
      const content = result.content[0];
      const text = content?.type === "text" ? content.text : "(no output)";

      if (expanded) {
        return new Markdown(text.trim(), 0, 0, mdTheme);
      }

      const preview = text.split("\n").slice(0, 5).join("\n");
      let rendered = theme.fg("toolOutput", preview);
      if (text.split("\n").length > 5) {
        rendered += `\n${theme.fg("muted", "(Ctrl+O to expand)")}`;
      }
      return new Text(rendered, 0, 0);
    },
  });
}
