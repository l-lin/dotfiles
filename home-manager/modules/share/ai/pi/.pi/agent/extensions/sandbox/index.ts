/**
 * Sandbox Extension - OS-level sandboxing for bash commands
 *
 * Uses @anthropic-ai/sandbox-runtime to enforce filesystem and network
 * restrictions on bash commands at the OS level (sandbox-exec on macOS,
 * bubblewrap on Linux).
 *
 * Config files (merged, project takes precedence):
 * - ~/.pi/agent/sandbox.json (global)
 * - <cwd>/.pi/sandbox.json (project-local)
 *
 * Example .pi/sandbox.json:
 * ```json
 * {
 *   "enabled": true,
 *   "network": {
 *     "allowedDomains": ["github.com", "*.github.com"],
 *     "deniedDomains": [],
 *     "allowUnixSockets": ["/private/tmp/tmux-501"],
 *     "allowLocalBinding": true
 *   },
 *   "filesystem": {
 *     "denyRead": ["~/.ssh", "~/.aws"],
 *     "allowWrite": [".", "/tmp"],
 *     "denyWrite": [".env"]
 *   }
 * }
 * ```
 *
 * Usage:
 * - `pi -e ./sandbox` - sandbox enabled with default/config settings
 * - `pi -e ./sandbox --no-sandbox` - disable sandboxing
 * - `/sandbox-toggle` - toggle sandboxing on/off (persisted to ~/.pi/agent/settings.json)
 * - `/sandbox` - show current sandbox configuration
 *
 * Setup:
 * 1. Copy sandbox/ directory to ~/.pi/agent/extensions/
 * 2. Run `npm install` in ~/.pi/agent/extensions/sandbox/
 *
 * Linux also requires: bubblewrap, socat, ripgrep
 *
 * src: https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent/examples/extensions/sandbox
 */

import { spawn } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { SandboxManager } from "@anthropic-ai/sandbox-runtime";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
  type BashOperations,
  createBashTool,
  getAgentDir,
} from "@mariozechner/pi-coding-agent";
import {
  disableSandbox,
  ensureSandboxActive,
  type SandboxConfig,
} from "./activation.js";
import { createDefaultConfig } from "./default-config.js";
import {
  loadSandboxEnabledSettings,
  saveSandboxEnabledSettings,
} from "./settings.js";
import { registerSandboxToggleCommand } from "./toggle-command.js";

function loadConfig(cwd: string): SandboxConfig {
  const projectConfigPath = join(cwd, ".pi", "sandbox.json");
  const globalConfigPath = join(getAgentDir(), "extensions", "sandbox.json");

  let globalConfig: Partial<SandboxConfig> = {};
  let projectConfig: Partial<SandboxConfig> = {};

  if (existsSync(globalConfigPath)) {
    try {
      globalConfig = JSON.parse(readFileSync(globalConfigPath, "utf-8"));
    } catch (e) {
      console.error(`Warning: Could not parse ${globalConfigPath}: ${e}`);
    }
  }

  if (existsSync(projectConfigPath)) {
    try {
      projectConfig = JSON.parse(readFileSync(projectConfigPath, "utf-8"));
    } catch (e) {
      console.error(`Warning: Could not parse ${projectConfigPath}: ${e}`);
    }
  }

  return deepMerge(
    deepMerge(createDefaultConfig(), globalConfig),
    projectConfig,
  );
}

function deepMerge(
  base: SandboxConfig,
  overrides: Partial<SandboxConfig>,
): SandboxConfig {
  const result: SandboxConfig = { ...base };

  if (overrides.enabled !== undefined) result.enabled = overrides.enabled;
  if (overrides.network) {
    result.network = { ...base.network, ...overrides.network };
  }
  if (overrides.filesystem) {
    result.filesystem = { ...base.filesystem, ...overrides.filesystem };
  }

  const extOverrides = overrides as {
    ignoreViolations?: Record<string, string[]>;
    enableWeakerNestedSandbox?: boolean;
  };
  const extResult = result as {
    ignoreViolations?: Record<string, string[]>;
    enableWeakerNestedSandbox?: boolean;
  };

  if (extOverrides.ignoreViolations) {
    extResult.ignoreViolations = extOverrides.ignoreViolations;
  }
  if (extOverrides.enableWeakerNestedSandbox !== undefined) {
    extResult.enableWeakerNestedSandbox =
      extOverrides.enableWeakerNestedSandbox;
  }

  return result;
}

function createSandboxedBashOps(): BashOperations {
  return {
    async exec(command, cwd, { onData, signal, timeout }) {
      if (!existsSync(cwd)) {
        throw new Error(`Working directory does not exist: ${cwd}`);
      }

      const wrappedCommand = await SandboxManager.wrapWithSandbox(command);

      return new Promise((resolve, reject) => {
        const child = spawn("bash", ["-c", wrappedCommand], {
          cwd,
          detached: true,
          stdio: ["ignore", "pipe", "pipe"],
        });

        let timedOut = false;
        let timeoutHandle: NodeJS.Timeout | undefined;

        if (timeout !== undefined && timeout > 0) {
          timeoutHandle = setTimeout(() => {
            timedOut = true;
            if (child.pid) {
              try {
                process.kill(-child.pid, "SIGKILL");
              } catch {
                child.kill("SIGKILL");
              }
            }
          }, timeout * 1000);
        }

        child.stdout?.on("data", onData);
        child.stderr?.on("data", onData);

        child.on("error", (err) => {
          if (timeoutHandle) clearTimeout(timeoutHandle);
          reject(err);
        });

        const onAbort = () => {
          if (child.pid) {
            try {
              process.kill(-child.pid, "SIGKILL");
            } catch {
              child.kill("SIGKILL");
            }
          }
        };

        signal?.addEventListener("abort", onAbort, { once: true });

        child.on("close", (code) => {
          if (timeoutHandle) clearTimeout(timeoutHandle);
          signal?.removeEventListener("abort", onAbort);

          if (signal?.aborted) {
            reject(new Error("aborted"));
          } else if (timedOut) {
            reject(new Error(`timeout:${timeout}`));
          } else {
            resolve({ exitCode: code });
          }
        });
      });
    },
  };
}

export default function (pi: ExtensionAPI) {
  pi.registerFlag("no-sandbox", {
    description: "Disable OS-level sandboxing for bash commands",
    type: "boolean",
    default: false,
  });

  const settings = loadSandboxEnabledSettings();
  const localCwd = process.cwd();
  const localBash = createBashTool(localCwd);
  const sandboxState = {
    enabled: false,
    initialized: false,
  };

  function emitSandboxStateChanged(enabled: boolean): void {
    pi.events.emit("sandbox:state-changed", enabled);
  }

  async function disableSandboxForCurrentSession(): Promise<void> {
    await disableSandbox({
      state: sandboxState,
      reset: () => SandboxManager.reset(),
      emitStateChanged: emitSandboxStateChanged,
    });
  }

  async function enableSandboxForCurrentSession(ctx: {
    cwd: string;
  }): Promise<
    { message: string; type: "info" | "warning" | "error" } | undefined
  > {
    return ensureSandboxActive({
      state: sandboxState,
      settingsEnabled: settings.enabled,
      noSandbox: pi.getFlag("no-sandbox") as boolean,
      platform: process.platform,
      cwd: ctx.cwd,
      loadConfig,
      initialize: async (config) => {
        await SandboxManager.initialize({
          network: config.network,
          filesystem: config.filesystem,
          ignoreViolations: config.ignoreViolations,
          enableWeakerNestedSandbox: config.enableWeakerNestedSandbox,
        });
      },
      reset: () => SandboxManager.reset(),
      emitStateChanged: emitSandboxStateChanged,
    });
  }

  registerSandboxToggleCommand(pi, {
    settings,
    saveEnabled: saveSandboxEnabledSettings,
    applySettingChange: async (enabled, ctx) => {
      if (!enabled) {
        await disableSandboxForCurrentSession();
        return undefined;
      }

      return enableSandboxForCurrentSession(ctx);
    },
  });

  pi.registerTool({
    ...localBash,
    label: "bash (sandboxed)",
    async execute(id, params, signal, onUpdate, _ctx) {
      if (!sandboxState.enabled || !sandboxState.initialized) {
        return localBash.execute(id, params, signal, onUpdate);
      }

      const sandboxedBash = createBashTool(localCwd, {
        operations: createSandboxedBashOps(),
      });
      return sandboxedBash.execute(id, params, signal, onUpdate);
    },
  });

  pi.on("user_bash", () => {
    if (!sandboxState.enabled || !sandboxState.initialized) return;
    return { operations: createSandboxedBashOps() };
  });

  pi.on("session_start", async (_event, ctx) => {
    const notification = await enableSandboxForCurrentSession(ctx);

    if (notification) {
      ctx.ui.notify(notification.message, notification.type);
    }
  });

  pi.on("session_shutdown", async () => {
    await disableSandboxForCurrentSession();
  });

  pi.registerCommand("cmd:sandbox", {
    description: "Show sandbox configuration",
    handler: async (_args, ctx) => {
      if (!sandboxState.enabled) {
        ctx.ui.notify("Sandbox is disabled", "info");
        return;
      }

      const config = loadConfig(ctx.cwd);
      const lines = [
        "Sandbox Configuration:",
        "",
        "Network:",
        `  Allowed: ${config.network?.allowedDomains?.join(", ") || "(none)"}`,
        `  Denied: ${config.network?.deniedDomains?.join(", ") || "(none)"}`,
        `  Unix Sockets: ${config.network?.allowUnixSockets?.join(", ") || "(none)"}`,
        `  Local Binding: ${config.network?.allowLocalBinding ? "allowed" : "blocked"}`,
        "",
        "Filesystem:",
        `  Deny Read: ${config.filesystem?.denyRead?.join(", ") || "(none)"}`,
        `  Allow Write: ${config.filesystem?.allowWrite?.join(", ") || "(none)"}`,
        `  Deny Write: ${config.filesystem?.denyWrite?.join(", ") || "(none)"}`,
      ];
      ctx.ui.notify(lines.join("\n"), "info");
    },
  });
}
