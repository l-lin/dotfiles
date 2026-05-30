/**
 * Red-Team Extension — critical, skeptical engineer mode
 *
 * Activates a read-only tool environment and injects system prompt instructions
 * to challenge every decision. Toggle with /red-team (per-session only).
 *
 * When ON:
 * - Only read-oriented tools are available (no edit, write)
 * - Bash commands are filtered to block write operations
 * - System prompt instructs the agent to be critical and skeptical
 * - Status badge "🔴 red-team" appears in the footer
 *
 * When OFF:
 * - All default tools restored
 * - System prompt injection removed
 * - Badge cleared
 *
 * src: local
 */
import type {
  ExtensionAPI,
  ExtensionContext,
  ToolCallEvent,
} from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";

// ── Constants ────────────────────────────────────────────────────────────────

const RED_TEAM_TOOLS = [
  "read",
  "web-fetch",
  "web-search",
  "ask-user-question",
  "find",
  "ls",
  "grep",
  "bash",
];

const RED_TEAM_PROMPT = `You are a critical, skeptical engineer.
For every task:
1) Challenge the approach
2) Identify failure modes
3) Question assumptions
4) Suggest safer alternatives
5) Only approve after thorough review
Never rubber-stamp decisions.`;

// ── Bash filtering ───────────────────────────────────────────────────────────

/** Patterns that indicate a write operation in bash */
const BLOCKED_BASH_PATTERNS = [
  { regex: /\brm\b/, reason: "File deletion is not allowed" },
  { regex: /\bmv\b/, reason: "File move is not allowed" },
  { regex: /\bc\b(?!ommands?\b)/, reason: "File copy is not allowed" },
  { regex: /\bcp\b/, reason: "File copy is not allowed" },
  { regex: /\bmkdir\b/, reason: "Directory creation is not allowed" },
  { regex: /\btouch\b/, reason: "File creation is not allowed" },
  { regex: /\bsed\s+.*-i\b/, reason: "In-place file editing is not allowed" },
  { regex: /\btee\b/, reason: "Pipe write is not allowed" },
  { regex: />\s*/, reason: "Output redirection is not allowed" },
  { regex: /\b>\s*/, reason: "Output redirection is not allowed" },
];

interface RuntimeState {
  enabled: boolean;
  previousTools: string[];
}

function isBashBlocked(
  command: string,
): { blocked: true; reason: string } | { blocked: false } {
  for (const { regex, reason } of BLOCKED_BASH_PATTERNS) {
    if (regex.test(command)) {
      return { blocked: true, reason };
    }
  }
  return { blocked: false };
}

// ── Extension ────────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  let runtimeState: RuntimeState = {
    enabled: false,
    previousTools: [],
  };

  function enable(ctx: ExtensionContext): void {
    runtimeState.enabled = true;
    runtimeState.previousTools = pi.getActiveTools();
    pi.setActiveTools(RED_TEAM_TOOLS);
    ctx.ui.setStatus("red-team", ctx.ui.theme.fg("error", "󱚝"));
  }

  function disable(ctx: ExtensionContext): void {
    runtimeState.enabled = false;
    pi.setActiveTools(runtimeState.previousTools);
    ctx.ui.setStatus("red-team", undefined);
  }

  // ── Toggle command ───────────────────────────────────────────────────────

  pi.registerCommand("cmd:red-team", {
    description: "Toggle red-team mode (read-only, critical engineer)",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;

      if (runtimeState.enabled) {
        disable(ctx);
      } else {
        enable(ctx);
      }
    },
  });

  // ── System prompt injection ──────────────────────────────────────────────

  pi.on("before_agent_start", async (event) => {
    if (!runtimeState.enabled) {
      return undefined;
    }

    return {
      systemPrompt: `${event.systemPrompt}\n\n${RED_TEAM_PROMPT}`,
    };
  });

  // ── Bash command filtering ───────────────────────────────────────────────

  pi.on("tool_call", async (event: ToolCallEvent, ctx: ExtensionContext) => {
    if (!runtimeState.enabled) {
      return undefined;
    }

    if (!isToolCallEventType("bash", event)) {
      return undefined;
    }

    const command = event.input.command;
    const check = isBashBlocked(command);

    if (check.blocked) {
      const reason =
        "Red-team mode is active. Write operations are not allowed.";

      if (!ctx.hasUI) {
        ctx.abort();
        return { block: true, reason };
      }

      ctx.ui.notify(`⚠️ Blocked: ${check.reason}`, "warning");
      ctx.abort();
      return { block: true, reason };
    }

    return undefined;
  });
}
