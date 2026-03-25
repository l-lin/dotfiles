/**
 * Pre-Tool Safety Extension for Pi
 *
 * Integrates with ~/.config/ai/hooks/pre-tool-safety/main.rb to block
 * dangerous bash commands and reads of sensitive files before execution.
 *
 * ## Monitored Tools
 * - **bash**: Checks for destructive operations, privilege escalation, secrets access, network exfil
 * - **read**: Blocks reads of sensitive paths (.ssh, .aws, .gnupg) and key material
 *
 * ## Configuration
 * - **SAFETY_HOOK_PATH**: Override default hook script path (default: ~/.config/ai/hooks/pre-tool-safety/main.rb)
 * - **SAFETY_HOOK_DEBUG**: Enable debug logging (set to "1")
 *
 * ## Behavior
 * - **Hook script missing**: Fail open (allow all operations, warn on load)
 * - **Hook script error**: Fail closed (block operation with error message)
 * - **Timeout (5s)**: Fail closed (block operation)
 *
 * @see ~/.config/ai/hooks/pre-tool-safety/main.rb - Ruby safety checker implementation
 */

import type {
  ExtensionAPI,
  ExtensionContext,
  ToolCallEvent,
} from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export default function (pi: ExtensionAPI) {
  const DEFAULT_HOOK_PATH = join(
    homedir(),
    ".config/ai/hooks/pre-tool-safety/main.rb",
  );
  const HOOK_PATH = process.env.SAFETY_HOOK_PATH || DEFAULT_HOOK_PATH;
  const HOOK_TIMEOUT_MS = 5000;
  const DEBUG = process.env.SAFETY_HOOK_DEBUG === "1";

  const hookAvailable = existsSync(HOOK_PATH);
  if (!hookAvailable) {
    console.warn(`[pre-tool-safety] Hook script not found: ${HOOK_PATH}`);
    console.warn(
      `[pre-tool-safety] Safety checks disabled. Operations will be allowed.`,
    );
  } else if (DEBUG) {
    console.log(`[pre-tool-safety] Hook script found: ${HOOK_PATH}`);
  }

  function debug(message: string, data?: unknown) {
    if (DEBUG) {
      console.log(
        `[pre-tool-safety] ${message}`,
        data !== undefined ? JSON.stringify(data, null, 2) : "",
      );
    }
  }

  interface SafetyCheckInput {
    session_id: string;
    transcript_path: string | null;
    cwd: string;
    permission_mode: "default";
    hook_event_name: "PreToolUse";
    tool_name: "Bash" | "Read";
    tool_input: Record<string, unknown>;
    tool_use_id: string;
  }

  interface SafetyCheckResult {
    allowed: boolean;
    reason?: string;
  }

  function buildSafetyInput(
    toolCallId: string,
    toolName: "Bash" | "Read",
    toolInput: Record<string, unknown>,
    ctx: ExtensionContext,
  ): SafetyCheckInput {
    const sessionFile = ctx.sessionManager.getSessionFile();
    return {
      session_id: sessionFile || "pi-session",
      transcript_path: sessionFile || null,
      cwd: ctx.cwd,
      permission_mode: "default",
      hook_event_name: "PreToolUse",
      tool_name: toolName,
      tool_input: toolInput,
      tool_use_id: toolCallId,
    };
  }

  async function checkSafety(
    input: SafetyCheckInput,
  ): Promise<SafetyCheckResult> {
    return new Promise((resolve) => {
      debug("Starting safety check", input);

      const child = spawn("ruby", [HOOK_PATH]);
      let stdout = "";
      let stderr = "";
      let timedOut = false;

      const timeout = setTimeout(() => {
        timedOut = true;
        child.kill();
        debug("Safety check timed out");
        resolve({ allowed: false, reason: "Safety check timed out" });
      }, HOOK_TIMEOUT_MS);

      child.stdout.on("data", (data) => {
        stdout += data.toString();
      });
      child.stderr.on("data", (data) => {
        stderr += data.toString();
      });

      child.on("close", (code) => {
        clearTimeout(timeout);
        if (timedOut) return;

        debug(`Safety check exited with code ${code}`, { stdout, stderr });

        if (code === 0) {
          debug("Safety check: ALLOWED");
          resolve({ allowed: true });
          return;
        }

        if (code === 2) {
          try {
            const parsed = JSON.parse(stdout);
            const reason =
              parsed?.hookSpecificOutput?.permissionDecisionReason ||
              "Operation blocked by safety check";
            debug("Safety check: DENIED", { reason });
            resolve({ allowed: false, reason });
          } catch (err) {
            debug("Failed to parse denial JSON", {
              error: String(err),
              stdout,
            });
            resolve({
              allowed: false,
              reason: "Safety check blocked operation (parse error)",
            });
          }
          return;
        }

        debug("Safety check error", { code, stderr });
        resolve({
          allowed: false,
          reason: `Safety check failed (exit ${code})`,
        });
      });

      child.on("error", (err) => {
        clearTimeout(timeout);
        if (timedOut) return;
        debug("Failed to spawn Ruby process", { error: String(err) });
        resolve({
          allowed: false,
          reason: `Safety check error: ${err.message}`,
        });
      });

      try {
        child.stdin.write(JSON.stringify(input));
        child.stdin.end();
        debug("Sent input to Ruby process");
      } catch (err) {
        clearTimeout(timeout);
        child.kill();
        debug("Failed to write to stdin", { error: String(err) });
        resolve({
          allowed: false,
          reason: `Failed to write to safety check: ${err}`,
        });
      }
    });
  }

  function blockIfDenied(result: SafetyCheckResult, ctx: ExtensionContext) {
    if (result.allowed) return undefined;
    if (ctx.hasUI) {
      ctx.ui.notify(`🛑 ${result.reason}`, "warning");
    }
    return {
      block: true,
      reason: result.reason || "Operation blocked by safety check",
    };
  }

  pi.on("tool_call", async (event: ToolCallEvent, ctx: ExtensionContext) => {
    if (!hookAvailable) return undefined;

    if (isToolCallEventType("bash", event)) {
      const input = buildSafetyInput(
        event.toolCallId,
        "Bash",
        { command: event.input.command },
        ctx,
      );
      return blockIfDenied(await checkSafety(input), ctx);
    }

    if (isToolCallEventType("read", event)) {
      // Ruby script expects file_path, not path
      const input = buildSafetyInput(
        event.toolCallId,
        "Read",
        { file_path: event.input.path },
        ctx,
      );
      return blockIfDenied(await checkSafety(input), ctx);
    }

    return undefined;
  });
}
