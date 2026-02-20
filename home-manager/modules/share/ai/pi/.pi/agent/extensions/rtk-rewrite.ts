/**
 * RTK Rewrite Extension for Pi
 *
 * Intercepts bash tool calls and rewrites commands to their `rtk` equivalents
 * before execution, reducing token usage in LLM responses.
 *
 * Uses the rtk-rewrite.sh hook to determine if/how to rewrite a command.
 * When a rewrite is found, the extension executes the rtk version itself and
 * returns the (compressed) output to the LLM — bypassing the original command.
 *
 * ## Requirements
 * - `rtk` must be installed: https://github.com/rtk-ai/rtk
 * - `jq` must be available
 *
 * ## Configuration
 * - RTK_HOOK_PATH: Override hook script path
 *   Default: ~/.config/ai/hooks/rtk-rewrite.sh
 * - RTK_HOOK_DEBUG: Enable debug logging (set to "1")
 *
 * ## Behavior
 * - rtk/jq missing: fail open (pass through all commands)
 * - Hook script missing: fail open (pass through all commands)
 * - Rewrite found: execute rtk command, return compressed output to LLM
 * - No rewrite: allow bash tool to execute normally
 * - Timeout (10s for hook, 60s for command): fall back to original
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
  const DEFAULT_HOOK_PATH = join(homedir(), ".config/ai/hooks/rtk-rewrite.sh");
  const HOOK_PATH = process.env.RTK_HOOK_PATH || DEFAULT_HOOK_PATH;
  const HOOK_TIMEOUT_MS = 10_000;
  const CMD_TIMEOUT_MS = 60_000;
  const DEBUG = process.env.RTK_HOOK_DEBUG === "1";

  function debug(message: string, data?: unknown) {
    if (DEBUG) {
      console.log(
        `[rtk-rewrite] ${message}`,
        data !== undefined ? JSON.stringify(data) : "",
      );
    }
  }

  let hookAvailable = false;
  try {
    hookAvailable = existsSync(HOOK_PATH);
    if (!hookAvailable) {
      console.warn(`[rtk-rewrite] Hook script not found: ${HOOK_PATH}`);
      console.warn(`[rtk-rewrite] RTK rewrites disabled.`);
    } else {
      debug(`Hook script found: ${HOOK_PATH}`);
    }
  } catch (err) {
    console.warn(`[rtk-rewrite] Failed to check hook script: ${err}`);
  }

  /**
   * Ask rtk-rewrite.sh if the command should be rewritten.
   * Returns the rewritten command string, or null if no rewrite is needed.
   */
  async function getRewrittenCommand(
    command: string,
    cwd: string,
  ): Promise<string | null> {
    return new Promise((resolve) => {
      const input = JSON.stringify({ tool_input: { command } });
      const child = spawn("bash", [HOOK_PATH], { cwd });
      let stdout = "";
      let timedOut = false;

      const timeout = setTimeout(() => {
        timedOut = true;
        child.kill();
        debug("Hook timed out");
        resolve(null);
      }, HOOK_TIMEOUT_MS);

      child.stdout.on("data", (data: Buffer) => {
        stdout += data.toString();
      });

      child.on("close", (_code: number | null) => {
        clearTimeout(timeout);
        if (timedOut) return;

        const trimmed = stdout.trim();
        if (!trimmed) {
          debug("No rewrite");
          resolve(null);
          return;
        }

        try {
          const parsed = JSON.parse(trimmed);
          const rewritten: string | undefined =
            parsed?.hookSpecificOutput?.updatedInput?.command;
          if (rewritten) {
            debug(`Rewriting: ${command} → ${rewritten}`);
            resolve(rewritten);
          } else {
            resolve(null);
          }
        } catch (err) {
          debug("Failed to parse hook output", { error: String(err), stdout });
          resolve(null);
        }
      });

      child.on("error", (err: Error) => {
        clearTimeout(timeout);
        if (timedOut) return;
        debug("Failed to spawn hook", { error: String(err) });
        resolve(null);
      });

      try {
        child.stdin.write(input);
        child.stdin.end();
      } catch (err) {
        clearTimeout(timeout);
        child.kill();
        debug("Failed to write to hook stdin", { error: String(err) });
        resolve(null);
      }
    });
  }

  /**
   * Execute a shell command and return its combined stdout+stderr output.
   */
  async function runCommand(
    command: string,
    cwd: string,
  ): Promise<{ output: string; exitCode: number }> {
    return new Promise((resolve) => {
      const child = spawn("bash", ["-c", command], { cwd });
      let output = "";
      let timedOut = false;

      const timeout = setTimeout(() => {
        timedOut = true;
        child.kill();
        debug("Command timed out", { command });
        resolve({
          output: `[rtk-rewrite] Command timed out after ${CMD_TIMEOUT_MS / 1000}s`,
          exitCode: 1,
        });
      }, CMD_TIMEOUT_MS);

      child.stdout.on("data", (data: Buffer) => {
        output += data.toString();
      });
      child.stderr.on("data", (data: Buffer) => {
        output += data.toString();
      });

      child.on("close", (code: number | null, signal: NodeJS.Signals | null) => {
        clearTimeout(timeout);
        if (timedOut) return;
        // code is null when process was killed by a signal
        const exitCode = code !== null ? code : signal ? 1 : 0;
        resolve({ output, exitCode });
      });

      child.on("error", (err: Error) => {
        clearTimeout(timeout);
        if (timedOut) return;
        resolve({
          output: `[rtk-rewrite] Failed to run command: ${err.message}`,
          exitCode: 1,
        });
      });
    });
  }

  pi.on("tool_call", async (event: ToolCallEvent, ctx: ExtensionContext) => {
    if (!hookAvailable) return undefined;
    if (!isToolCallEventType("bash", event)) return undefined;

    const originalCommand = event.input.command;
    const rewritten = await getRewrittenCommand(originalCommand, ctx.cwd);

    if (!rewritten) return undefined;

    // Notify before executing so user knows what's running
    if (ctx.hasUI) {
      ctx.ui.notify(`⚡ rtk: ${rewritten}`, "info");
    }

    debug(`Executing rewritten command: ${rewritten}`);
    const { output, exitCode } = await runCommand(rewritten, ctx.cwd);

    const result =
      exitCode !== 0
        ? `Exit code: ${exitCode}\n${output}`
        : output || "(no output)";

    return {
      block: true,
      reason: result,
    };
  });
}
