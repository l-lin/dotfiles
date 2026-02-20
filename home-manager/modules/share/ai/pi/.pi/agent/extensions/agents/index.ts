/**
 * Subagent Tool - Delegate tasks to specialized agents via tmux panes
 *
 * Spawns interactive `pi` instances in tmux split panes so the user
 * can see and steer sub-agents. Results are communicated back via
 * file-based IPC (sub-agent writes to a temp file).
 *
 * Supports two modes:
 *   - Single: { agent: "name", task: "..." }
 *   - Parallel: { tasks: [{ agent: "name", task: "..." }, ...] }
 *
 * Requires the main agent to be running inside tmux.
 */

import { execSync, spawn } from "node:child_process";
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

// ─── tmux helpers ────────────────────────────────────────────────────────────

function isInsideTmux(): boolean {
  return !!process.env.TMUX;
}

/** Split the current pane horizontally (new pane on the right), returns pane ID */
function tmuxSplitRight(cwd: string): string {
  const paneId = execSync(
    `tmux split-window -h -P -F '#{pane_id}' -c ${shellEscape(cwd)}`,
    { encoding: "utf-8" },
  ).trim();
  return paneId;
}

/** Send keys to a specific tmux pane */
function tmuxSendKeys(paneId: string, text: string): void {
  execSync(`tmux send-keys -t ${shellEscape(paneId)} ${shellEscape(text)} C-m`);
}

/** Wait for a tmux signal. Resolves when the signal fires or rejects on abort. */
function tmuxWaitFor(
  token: string,
  signal?: AbortSignal,
): Promise<void> {
  return new Promise((resolve, reject) => {
    if (signal?.aborted) {
      reject(new Error("Aborted"));
      return;
    }

    const proc = spawn("tmux", ["wait-for", token], { stdio: "ignore" });

    const onAbort = () => {
      proc.kill("SIGTERM");
      reject(new Error("Aborted"));
    };

    signal?.addEventListener("abort", onAbort, { once: true });

    proc.on("close", () => {
      signal?.removeEventListener("abort", onAbort);
      resolve();
    });

    proc.on("error", (err: Error) => {
      signal?.removeEventListener("abort", onAbort);
      reject(err);
    });
  });
}

/** Kill a tmux pane */
function tmuxKillPane(paneId: string): void {
  try {
    execSync(`tmux kill-pane -t ${shellEscape(paneId)}`, { stdio: "ignore" });
  } catch {
    // pane may already be dead
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

/** Shell-escape a string for safe use in commands */
function shellEscape(s: string): string {
  return `'${s.replace(/'/g, "'\\''")}'`;
}

// ─── temp file helpers ───────────────────────────────────────────────────────

function createTempResultFile(agentName: string): string {
  const safeName = agentName.replace(/[^\w.-]+/g, "_");
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-subagent-"));
  return path.join(tmpDir, `result-${safeName}.md`);
}

function writePromptToTempFile(
  agentName: string,
  prompt: string,
): { dir: string; filePath: string } {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-subagent-"));
  const safeName = agentName.replace(/[^\w.-]+/g, "_");
  const filePath = path.join(tmpDir, `prompt-${safeName}.md`);
  fs.writeFileSync(filePath, prompt, { encoding: "utf-8", mode: 0o600 });
  return { dir: tmpDir, filePath };
}

function cleanupTempFile(filePath: string): void {
  try {
    fs.unlinkSync(filePath);
  } catch { /* ignore */ }
  try {
    fs.rmdirSync(path.dirname(filePath));
  } catch { /* ignore */ }
}

function readResultFile(filePath: string): string {
  try {
    return fs.readFileSync(filePath, "utf-8");
  } catch {
    return "";
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
  if (agent.tools && agent.tools.length > 0) {
    parts.push("--tools", shellEscape(agent.tools.join(",")));
  }
  if (systemPromptFile) {
    parts.push("--append-system-prompt", shellEscape(systemPromptFile));
  }
  parts.push("--no-session");

  const augmentedTask = `${task}

IMPORTANT: When you have completed the task, you MUST write your final answer/summary to the file "${resultFile}" using the write tool. This is how your result gets communicated back to the calling agent. Do this as your very last action before finishing.`;

  parts.push(shellEscape(`Task: ${augmentedTask}`));

  return parts.join(" ");
}

// ─── core: run agent in tmux pane ────────────────────────────────────────────

async function runAgentInPane(
  agent: AgentConfig,
  task: string,
  cwd: string,
  signal?: AbortSignal,
): Promise<{ agent: string; agentSource: "user" | "project"; task: string; output: string; success: boolean }> {
  const resultFile = createTempResultFile(agent.name);
  const token = `PI_SUBAGENT_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

  let systemPromptFile: string | undefined;

  if (agent.systemPrompt.trim()) {
    const tmp = writePromptToTempFile(agent.name, agent.systemPrompt);
    systemPromptFile = tmp.filePath;
  }

  const paneId = tmuxSplitRight(cwd);

  try {
    const piCmd = buildPiCommand(agent, task, resultFile, systemPromptFile);
    // Wrap in login shell so env vars (PATH, API keys, etc.) are available
    // Sleep gives the pane's shell time to fully initialize
    const userShell = process.env.SHELL || "zsh";
    const fullCmd = `${userShell} -lc ${shellEscape(`sleep 1; ${piCmd}; tmux wait-for -S ${token}`)}`;
    tmuxSendKeys(paneId, fullCmd);

    await tmuxWaitFor(token, signal);

    const output = readResultFile(resultFile);

    return {
      agent: agent.name,
      agentSource: agent.source,
      task,
      output: output || "(sub-agent did not write a result file)",
      success: !!output,
    };
  } finally {
    // Cleanup: kill pane and temp files
    tmuxKillPane(paneId);
    cleanupTempFile(resultFile);
    if (systemPromptFile) cleanupTempFile(systemPromptFile);
  }
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

const SubagentParams = Type.Object({
  agent: Type.Optional(
    Type.String({
      description: "Name of the agent to invoke (for single mode)",
    }),
  ),
  task: Type.Optional(
    Type.String({ description: "Task to delegate (for single mode)" }),
  ),
  tasks: Type.Optional(
    Type.Array(TaskItem, {
      description: "Array of {agent, task} for parallel execution",
    }),
  ),
  agentScope: Type.Optional(AgentScopeSchema),
  confirmProjectAgents: Type.Optional(
    Type.Boolean({
      description: "Prompt before running project-local agents. Default: true.",
      default: true,
    }),
  ),
  cwd: Type.Optional(
    Type.String({
      description: "Working directory for the agent process (single mode)",
    }),
  ),
});

// ─── result types ────────────────────────────────────────────────────────────

interface AgentResult {
  agent: string;
  agentSource: "user" | "project" | "unknown";
  task: string;
  output: string;
  success: boolean;
}

interface SubagentDetails {
  mode: "single" | "parallel";
  agentScope: AgentScope;
  projectAgentsDir: string | null;
  results: AgentResult[];
}

// ─── extension ───────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Delegate tasks to specialized subagents in interactive tmux panes.",
      "The user can see and steer sub-agents. Results are written to a temp file by the sub-agent.",
      "Modes: single (agent + task), parallel (tasks array with side-by-side panes).",
      'Default agent scope is "user" (from ~/.pi/agent/agents).',
      'To enable project-local agents in .pi/agents, set agentScope: "both" (or "project").',
      "Requires running inside tmux.",
    ].join(" "),
    parameters: SubagentParams,

    async execute(_toolCallId, params, signal, onUpdate, ctx) {
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

      const agentScope: AgentScope = params.agentScope ?? "user";
      const discovery = discoverAgents(ctx.cwd, agentScope);
      const agents = discovery.agents;
      const confirmProjectAgents = params.confirmProjectAgents ?? true;

      const hasTasks = (params.tasks?.length ?? 0) > 0;
      const hasSingle = Boolean(params.agent && params.task);
      const modeCount = Number(hasTasks) + Number(hasSingle);

      const makeDetails =
        (mode: "single" | "parallel") =>
        (results: AgentResult[]): SubagentDetails => ({
          mode,
          agentScope,
          projectAgentsDir: discovery.projectAgentsDir,
          results,
        });

      if (modeCount !== 1) {
        const available =
          agents.map((a) => `${a.name} (${a.source})`).join(", ") || "none";
        return {
          content: [
            {
              type: "text",
              text: `Invalid parameters. Provide exactly one mode: single (agent+task) or parallel (tasks array).\nAvailable agents: ${available}`,
            },
          ],
          details: makeDetails("single")([]),
        };
      }

      // ── project agent confirmation ──
      if (
        (agentScope === "project" || agentScope === "both") &&
        confirmProjectAgents &&
        ctx.hasUI
      ) {
        const requestedAgentNames = new Set<string>();
        if (params.tasks)
          for (const t of params.tasks) requestedAgentNames.add(t.agent);
        if (params.agent) requestedAgentNames.add(params.agent);

        const projectAgentsRequested = Array.from(requestedAgentNames)
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
              details: makeDetails(hasTasks ? "parallel" : "single")([]),
            };
        }
      }

      // ── parallel mode ──
      if (params.tasks && params.tasks.length > 0) {
        if (params.tasks.length > MAX_PARALLEL_TASKS)
          return {
            content: [
              {
                type: "text",
                text: `Too many parallel tasks (${params.tasks.length}). Max is ${MAX_PARALLEL_TASKS}.`,
              },
            ],
            details: makeDetails("parallel")([]),
          };

        // Resolve all agents first
        const resolvedTasks: { agent: AgentConfig; task: string; cwd: string }[] = [];
        for (const t of params.tasks) {
          const agent = agents.find((a) => a.name === t.agent);
          if (!agent) {
            const available = agents.map((a) => `"${a.name}"`).join(", ") || "none";
            return {
              content: [
                {
                  type: "text",
                  text: `Unknown agent: "${t.agent}". Available agents: ${available}.`,
                },
              ],
              details: makeDetails("parallel")([]),
              isError: true,
            };
          }
          resolvedTasks.push({ agent, task: t.task, cwd: t.cwd ?? ctx.cwd });
        }

        if (onUpdate) {
          onUpdate({
            content: [
              {
                type: "text",
                text: `Spawning ${resolvedTasks.length} sub-agents in tmux panes...`,
              },
            ],
            details: makeDetails("parallel")([]),
          });
        }

        // Spawn all agents in parallel panes
        const promises = resolvedTasks.map((t) =>
          runAgentInPane(t.agent, t.task, t.cwd, signal).catch(
            (err): AgentResult => ({
              agent: t.agent.name,
              agentSource: t.agent.source,
              task: t.task,
              output: `Error: ${err.message}`,
              success: false,
            }),
          ),
        );

        // Rebalance layout after all panes are created
        tmuxEvenHorizontal();

        const results = await Promise.all(promises);
        const successCount = results.filter((r) => r.success).length;

        const summaries = results.map((r) => {
          const preview =
            r.output.length > 200
              ? `${r.output.slice(0, 200)}...`
              : r.output;
          return `[${r.agent}] ${r.success ? "✓" : "✗"}: ${preview || "(no output)"}`;
        });

        return {
          content: [
            {
              type: "text",
              text: `Parallel: ${successCount}/${results.length} succeeded\n\n${summaries.join("\n\n")}`,
            },
          ],
          details: makeDetails("parallel")(results),
        };
      }

      // ── single mode ──
      if (params.agent && params.task) {
        const agent = agents.find((a) => a.name === params.agent);
        if (!agent) {
          const available =
            agents.map((a) => `"${a.name}"`).join(", ") || "none";
          return {
            content: [
              {
                type: "text",
                text: `Unknown agent: "${params.agent}". Available agents: ${available}.`,
              },
            ],
            details: makeDetails("single")([]),
            isError: true,
          };
        }

        if (onUpdate) {
          onUpdate({
            content: [
              {
                type: "text",
                text: `Spawning "${agent.name}" in tmux pane... User can interact with the sub-agent directly.`,
              },
            ],
            details: makeDetails("single")([]),
          });
        }

        try {
          const result = await runAgentInPane(
            agent,
            params.task,
            params.cwd ?? ctx.cwd,
            signal,
          );

          return {
            content: [{ type: "text", text: result.output || "(no output)" }],
            details: makeDetails("single")([result]),
          };
        } catch (err: any) {
          return {
            content: [
              {
                type: "text",
                text: `Agent aborted or failed: ${err.message}`,
              },
            ],
            details: makeDetails("single")([
              {
                agent: agent.name,
                agentSource: agent.source,
                task: params.task,
                output: err.message,
                success: false,
              },
            ]),
            isError: true,
          };
        }
      }

      const available =
        agents.map((a) => `${a.name} (${a.source})`).join(", ") || "none";
      return {
        content: [
          {
            type: "text",
            text: `Invalid parameters. Available agents: ${available}`,
          },
        ],
        details: makeDetails("single")([]),
      };
    },

    renderCall(args, theme) {
      const scope: AgentScope = args.agentScope ?? "user";

      if (args.tasks && args.tasks.length > 0) {
        let text =
          theme.fg("toolTitle", theme.bold("subagent ")) +
          theme.fg("accent", `parallel (${args.tasks.length} panes)`) +
          theme.fg("muted", ` [${scope}]`);
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
        theme.fg("toolTitle", theme.bold("subagent ")) +
        theme.fg("accent", agentName) +
        theme.fg("muted", ` [${scope}] (tmux pane)`);
      text += `\n  ${theme.fg("dim", preview)}`;
      return new Text(text, 0, 0);
    },

    renderResult(result, { expanded }, theme) {
      const details = result.details as SubagentDetails | undefined;
      if (!details || details.results.length === 0) {
        const text = result.content[0];
        return new Text(
          text?.type === "text" ? text.text : "(no output)",
          0,
          0,
        );
      }

      const mdTheme = getMarkdownTheme();

      if (details.mode === "single" && details.results.length === 1) {
        const r = details.results[0];
        const icon = r.success
          ? theme.fg("success", "✓")
          : theme.fg("error", "✗");

        if (expanded) {
          const container = new Container();
          container.addChild(
            new Text(
              `${icon} ${theme.fg("toolTitle", theme.bold(r.agent))}${theme.fg("muted", ` (${r.agentSource})`)}`,
              0,
              0,
            ),
          );
          container.addChild(new Spacer(1));
          container.addChild(new Text(theme.fg("muted", "─── Task ───"), 0, 0));
          container.addChild(new Text(theme.fg("dim", r.task), 0, 0));
          container.addChild(new Spacer(1));
          container.addChild(
            new Text(theme.fg("muted", "─── Result ───"), 0, 0),
          );
          if (r.output) {
            container.addChild(new Markdown(r.output.trim(), 0, 0, mdTheme));
          } else {
            container.addChild(
              new Text(theme.fg("muted", "(no output)"), 0, 0),
            );
          }
          return container;
        }

        // Collapsed view
        const preview = r.output
          ? r.output.split("\n").slice(0, 5).join("\n")
          : "(no output)";
        let text = `${icon} ${theme.fg("toolTitle", theme.bold(r.agent))}${theme.fg("muted", ` (${r.agentSource})`)}`;
        text += `\n${theme.fg("toolOutput", preview)}`;
        if (r.output && r.output.split("\n").length > 5) {
          text += `\n${theme.fg("muted", "(Ctrl+O to expand)")}`;
        }
        return new Text(text, 0, 0);
      }

      if (details.mode === "parallel") {
        const successCount = details.results.filter((r) => r.success).length;
        const icon =
          successCount === details.results.length
            ? theme.fg("success", "✓")
            : theme.fg("warning", "◐");

        if (expanded) {
          const container = new Container();
          container.addChild(
            new Text(
              `${icon} ${theme.fg("toolTitle", theme.bold("parallel "))}${theme.fg("accent", `${successCount}/${details.results.length} tasks`)}`,
              0,
              0,
            ),
          );

          for (const r of details.results) {
            const rIcon = r.success
              ? theme.fg("success", "✓")
              : theme.fg("error", "✗");
            container.addChild(new Spacer(1));
            container.addChild(
              new Text(
                `${theme.fg("muted", "─── ")}${theme.fg("accent", r.agent)} ${rIcon}`,
                0,
                0,
              ),
            );
            container.addChild(
              new Text(
                theme.fg("muted", "Task: ") + theme.fg("dim", r.task),
                0,
                0,
              ),
            );
            if (r.output) {
              container.addChild(new Spacer(1));
              container.addChild(
                new Markdown(r.output.trim(), 0, 0, mdTheme),
              );
            } else {
              container.addChild(
                new Text(theme.fg("muted", "(no output)"), 0, 0),
              );
            }
          }
          return container;
        }

        // Collapsed view
        let text = `${icon} ${theme.fg("toolTitle", theme.bold("parallel "))}${theme.fg("accent", `${successCount}/${details.results.length} tasks`)}`;
        for (const r of details.results) {
          const rIcon = r.success
            ? theme.fg("success", "✓")
            : theme.fg("error", "✗");
          const preview = r.output
            ? r.output.split("\n").slice(0, 3).join("\n")
            : "(no output)";
          text += `\n\n${theme.fg("muted", "─── ")}${theme.fg("accent", r.agent)} ${rIcon}`;
          text += `\n${theme.fg("toolOutput", preview)}`;
        }
        text += `\n${theme.fg("muted", "(Ctrl+O to expand)")}`;
        return new Text(text, 0, 0);
      }

      const text = result.content[0];
      return new Text(text?.type === "text" ? text.text : "(no output)", 0, 0);
    },
  });
}
