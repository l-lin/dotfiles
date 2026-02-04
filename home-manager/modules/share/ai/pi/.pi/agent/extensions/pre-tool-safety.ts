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
 * ## Dangerous Patterns Detected
 * - Destructive FS: rm -rf, git clean -fdx, find -delete
 * - Destructive disk: dd, mkfs, diskutil erase
 * - Privilege escalation: sudo, su, doas, launchctl, systemctl
 * - Risky git: push --force, reset --hard, filter-repo
 * - Secrets access: SSH keys, AWS credentials, .env files, keychain
 * - Network exfil: curl|sh, scp, rsync, ssh, nc
 * - Obfuscation: eval, base64 -d | sh
 * - Script references: Analyzes referenced scripts for dangerous patterns
 *
 * ## Configuration
 * - **SAFETY_HOOK_PATH**: Override default hook script path (default: ~/.config/ai/hooks/pre-tool-safety/main.rb)
 * - **SAFETY_HOOK_DEBUG**: Enable debug logging (set to "1")
 *
 * ## Behavior
 * - **Hook script missing**: Fail open (allow all operations, warn on load)
 * - **Hook script error**: Fail closed (block operation with error message)
 * - **Timeout (5s)**: Fail closed (block operation)
 * - **UI available**: Shows notification when blocking
 * - **No UI mode**: Blocks silently with error in tool result
 *
 * ## Performance
 * - Typical check: <100ms added latency
 * - Timeout ensures <5s max wait
 * - Each tool call spawns independent Ruby process
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
import { homedir } from "node:os";
import { join } from "node:path";
import { existsSync } from "node:fs";

export default function (pi: ExtensionAPI) {
  // Configuration
  const DEFAULT_HOOK_PATH = join(
    homedir(),
    ".config/ai/hooks/pre-tool-safety/main.rb",
  );
  const HOOK_PATH = process.env.SAFETY_HOOK_PATH || DEFAULT_HOOK_PATH;
  const HOOK_TIMEOUT_MS = 5000;
  const DEBUG = process.env.SAFETY_HOOK_DEBUG === "1";

  // Check if hook script is available
  let hookAvailable = false;
  try {
    hookAvailable = existsSync(HOOK_PATH);
    if (!hookAvailable) {
      console.warn(`[pre-tool-safety] Hook script not found: ${HOOK_PATH}`);
      console.warn(
        `[pre-tool-safety] Safety checks disabled. Operations will be allowed.`,
      );
    } else if (DEBUG) {
      console.log(`[pre-tool-safety] Hook script found: ${HOOK_PATH}`);
    }
  } catch (err) {
    console.warn(`[pre-tool-safety] Failed to check hook script: ${err}`);
    console.warn(
      `[pre-tool-safety] Safety checks disabled. Operations will be allowed.`,
    );
  }

  // Helper: Debug logging
  function debug(message: string, data?: unknown) {
    if (DEBUG) {
      console.log(
        `[pre-tool-safety] ${message}`,
        data !== undefined ? JSON.stringify(data, null, 2) : "",
      );
    }
  }

  // Types
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

  // Core: Execute Ruby safety check
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

        // Exit 0 = allow
        if (code === 0) {
          debug("Safety check: ALLOWED");
          resolve({ allowed: true });
          return;
        }

        // Exit 2 = deny, parse JSON
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

        // Other exit codes = error, fail closed
        const reason = `Safety check failed (exit ${code})`;
        debug("Safety check error", { code, stderr });
        resolve({ allowed: false, reason });
      });

      child.on("error", (err) => {
        clearTimeout(timeout);
        if (timedOut) return;

        const reason = `Safety check error: ${err.message}`;
        debug("Failed to spawn Ruby process", { error: String(err) });
        resolve({ allowed: false, reason });
      });

      // Send input JSON to stdin
      try {
        const inputJson = JSON.stringify(input);
        child.stdin.write(inputJson);
        child.stdin.end();
        debug("Sent input to Ruby process");
      } catch (err) {
        clearTimeout(timeout);
        child.kill();
        const reason = `Failed to write to safety check: ${err}`;
        debug("Failed to write to stdin", { error: String(err) });
        resolve({ allowed: false, reason });
      }
    });
  }

  // Helper: Get session ID
  function getSessionId(ctx: ExtensionContext): string {
    const sessionFile = ctx.sessionManager.getSessionFile();
    return sessionFile || "pi-session";
  }

  // Helper: Build input for Bash tool
  function buildBashInput(
    toolCallId: string,
    command: string,
    ctx: ExtensionContext,
  ): SafetyCheckInput {
    return {
      session_id: getSessionId(ctx),
      transcript_path: ctx.sessionManager.getSessionFile() || null,
      cwd: ctx.cwd,
      permission_mode: "default",
      hook_event_name: "PreToolUse",
      tool_name: "Bash",
      tool_input: { command },
      tool_use_id: toolCallId,
    };
  }

  // Helper: Build input for Read tool
  function buildReadInput(
    toolCallId: string,
    path: string,
    ctx: ExtensionContext,
  ): SafetyCheckInput {
    return {
      session_id: getSessionId(ctx),
      transcript_path: ctx.sessionManager.getSessionFile() || null,
      cwd: ctx.cwd,
      permission_mode: "default",
      hook_event_name: "PreToolUse",
      tool_name: "Read",
      tool_input: { file_path: path }, // Note: Ruby script expects file_path, not path
      tool_use_id: toolCallId,
    };
  }

  // Event Handler: Session start (optional status)
  pi.on("session_start", (_event, ctx) => {
    if (hookAvailable) {
      debug("Pre-tool safety checks active");
    } else {
      debug("Pre-tool safety checks inactive (hook script not found)");
    }
  });

  // Event Handler: Intercept tool calls for safety checks
  pi.on("tool_call", async (event: ToolCallEvent, ctx: ExtensionContext) => {
    // Skip if hook not available (fail open)
    if (!hookAvailable) {
      return undefined;
    }

    // Handle bash tool
    if (isToolCallEventType("bash", event)) {
      const input = buildBashInput(event.toolCallId, event.input.command, ctx);
      const result = await checkSafety(input);

      if (!result.allowed) {
        if (ctx.hasUI) {
          ctx.ui.notify(`🛑 ${result.reason}`, "warning");
        }
        return {
          block: true,
          reason: result.reason || "Operation blocked by safety check",
        };
      }
      return undefined;
    }

    // Handle read tool
    if (isToolCallEventType("read", event)) {
      const input = buildReadInput(event.toolCallId, event.input.path, ctx);
      const result = await checkSafety(input);

      if (!result.allowed) {
        if (ctx.hasUI) {
          ctx.ui.notify(`🛑 ${result.reason}`, "warning");
        }
        return {
          block: true,
          reason: result.reason || "Operation blocked by safety check",
        };
      }
      return undefined;
    }

    // Other tools: pass through
    return undefined;
  });
}
