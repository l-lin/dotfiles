/**
 * Execution Timer Extension
 *
 * Tracks wall-clock time for each agent run and displays a summary notification
 * when the agent finishes. Shows total elapsed time broken down into estimated
 * LLM time and per-tool execution times.
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

interface ToolTiming {
  name: string;
  ms: number;
}

interface RunState {
  agentStart: number;
  toolStarts: Map<string, number>;
  toolTimings: ToolTiming[];
}

export default function (pi: ExtensionAPI) {
  let run: RunState | null = null;

  function formatMs(ms: number): string {
    if (ms < 1000) return `${ms}ms`;
    return `${(ms / 1000).toFixed(1)}s`;
  }

  pi.on("agent_start", (_event, _ctx) => {
    run = { agentStart: Date.now(), toolStarts: new Map(), toolTimings: [] };
  });

  pi.on("tool_execution_start", (event, _ctx) => {
    run?.toolStarts.set(event.toolCallId, Date.now());
  });

  pi.on("tool_execution_end", (event, _ctx) => {
    if (!run) return;
    const start = run.toolStarts.get(event.toolCallId);
    if (start !== undefined) {
      run.toolTimings.push({ name: event.toolName, ms: Date.now() - start });
      run.toolStarts.delete(event.toolCallId);
    }
  });

  pi.on("agent_end", (_event, ctx) => {
    if (!run || !ctx.hasUI) return;

    const totalMs = Date.now() - run.agentStart;
    const toolMs = run.toolTimings.reduce((sum, t) => sum + t.ms, 0);
    const llmMs = Math.max(0, totalMs - toolMs);

    const breakdown = [`󰧑 ${formatMs(llmMs)}`, ...run.toolTimings.map((t) => `${t.name} ${formatMs(t.ms)}`)];
    const message = ` ${formatMs(totalMs)} (${breakdown.join(" + ")})`;

    ctx.ui.notify(message, "info");
    run = null;
  });
}
