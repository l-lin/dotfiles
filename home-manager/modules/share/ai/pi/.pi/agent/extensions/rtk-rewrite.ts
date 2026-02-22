/**
 * RTK Rewrite Extension for Pi
 *
 * Overrides the built-in bash tool to rewrite commands to their `rtk`
 * equivalents before execution, reducing token usage in LLM responses.
 *
 * Uses the rtk-rewrite.sh hook to determine if/how to rewrite a command.
 * When a rewrite is found, the rewritten command is passed to the original
 * bash tool implementation — result shape, rendering, and truncation are
 * all handled by pi's built-in bash tool.
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
 * - Rewrite found: execute rewritten command via built-in bash tool
 * - No rewrite: delegate to built-in bash tool unchanged
 * - Timeout (10s for hook): fall back to original command
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { createBashTool } from "@mariozechner/pi-coding-agent";
import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import { existsSync } from "node:fs";

export default function (pi: ExtensionAPI) {
  const DEFAULT_HOOK_PATH = join(homedir(), ".config/ai/hooks/rtk-rewrite.sh");
  const HOOK_PATH = process.env.RTK_HOOK_PATH || DEFAULT_HOOK_PATH;
  const HOOK_TIMEOUT_MS = 10_000;
  const DEBUG = process.env.RTK_HOOK_DEBUG === "1";

  function debug(message: string, data?: unknown) {
    if (DEBUG) {
      console.log(
        `[rtk] ${message}`,
        data !== undefined ? JSON.stringify(data) : "",
      );
    }
  }

  let hookAvailable = false;
  try {
    hookAvailable = existsSync(HOOK_PATH);
    if (!hookAvailable) {
      console.warn(`[rtk] Hook script not found: ${HOOK_PATH}`);
      console.warn(`[rtk] RTK rewrites disabled.`);
    } else {
      debug(`Hook script found: ${HOOK_PATH}`);
    }
  } catch (err) {
    console.warn(`[rtk] Failed to check hook script: ${err}`);
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

  const bashTool = createBashTool(process.cwd());

  pi.registerTool({
    ...bashTool,
    name: "bash",
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      if (hookAvailable) {
        const rewritten = await getRewrittenCommand(params.command, ctx.cwd);
        if (rewritten) {
          if (ctx.hasUI) ctx.ui.notify(`⚡ [rtk] ${rewritten}`, "info");
          debug(`Executing rewritten command: ${rewritten}`);
          return bashTool.execute(
            toolCallId,
            { ...params, command: rewritten },
            signal,
            onUpdate,
          );
        }
      }

      return bashTool.execute(toolCallId, params, signal, onUpdate);
    },

    renderCall(args, theme) {
      const command = args.command || "...";
      const timeout = args.timeout as number | undefined;
      const timeoutSuffix = timeout
        ? theme.fg("muted", ` (timeout ${timeout}s)`)
        : "";

      return new Text(
        theme.fg("toolTitle", theme.bold(`$ ${command}`)) + timeoutSuffix,
        0,
        0,
      );
    },

    renderResult(result, { expanded }, theme) {
      // Minimal mode: show nothing in collapsed state
      if (!expanded) {
        return new Text("", 0, 0);
      }

      // Expanded mode: show full output
      const textContent = result.content.find((c) => c.type === "text");
      if (!textContent || textContent.type !== "text") {
        return new Text("", 0, 0);
      }

      const output = textContent.text
        .trim()
        .split("\n")
        .map((line) => theme.fg("toolOutput", line))
        .join("\n");

      if (!output) {
        return new Text("", 0, 0);
      }

      return new Text(`\n${output}`, 0, 0);
    },
  });
}
