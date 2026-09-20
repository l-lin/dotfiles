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
import type {
  BashOperations,
  ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import { createBashTool, getAgentDir } from "@earendil-works/pi-coding-agent";
import type { SandboxConfig } from "./activation.js";
import {
  loadSandboxEnabledSettings,
  saveSandboxEnabledSettings,
} from "./settings.js";
import { registerSandboxToggleCommand } from "./toggle-command.js";
import {
  readYoloToggleStateChangedEvent,
  YOLO_SET_SANDBOX_ENABLED_EVENT,
} from "../yolo/events.js";

type SandboxNotification = {
  message: string;
  type: "info" | "warning" | "error";
};

type SandboxRuntimeModules = {
  sandboxManager: (typeof import("@anthropic-ai/sandbox-runtime"))["SandboxManager"];
  disableSandbox: (typeof import("./activation.js"))["disableSandbox"];
  ensureSandboxActive: (typeof import("./activation.js"))["ensureSandboxActive"];
  prepareSandboxedCommand: (typeof import("./command-adjustments.js"))["prepareSandboxedCommand"];
  rewriteSandboxRuntimeLoopbackHosts: (typeof import("./command-adjustments.js"))["rewriteSandboxRuntimeLoopbackHosts"];
  createDefaultConfig: (typeof import("./default-config.js"))["createDefaultConfig"];
};

// keep the external sandbox runtime out of launch; the first explicit bash owns activation.
let sandboxRuntimePromise: Promise<SandboxRuntimeModules> | undefined;

function loadSandboxRuntime(): Promise<SandboxRuntimeModules> {
  if (sandboxRuntimePromise) return sandboxRuntimePromise;

  const loading = Promise.all([
    import("@anthropic-ai/sandbox-runtime"),
    import("./activation.js"),
    import("./command-adjustments.js"),
    import("./default-config.js"),
  ]).then(
    ([sandboxRuntime, activation, commandAdjustments, defaultConfig]) => ({
      sandboxManager: sandboxRuntime.SandboxManager,
      disableSandbox: activation.disableSandbox,
      ensureSandboxActive: activation.ensureSandboxActive,
      prepareSandboxedCommand: commandAdjustments.prepareSandboxedCommand,
      rewriteSandboxRuntimeLoopbackHosts:
        commandAdjustments.rewriteSandboxRuntimeLoopbackHosts,
      createDefaultConfig: defaultConfig.createDefaultConfig,
    }),
  );

  sandboxRuntimePromise = loading.catch((error) => {
    sandboxRuntimePromise = undefined;
    throw error;
  });
  return sandboxRuntimePromise;
}

async function loadSandboxConfig(cwd: string): Promise<SandboxConfig> {
  const { createDefaultConfig } = await import("./default-config.js");
  return loadConfig(cwd, createDefaultConfig);
}

function loadConfig(
  cwd: string,
  createDefaultConfig: SandboxRuntimeModules["createDefaultConfig"],
): SandboxConfig {
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

function createSandboxedBashOps(
  runtime: SandboxRuntimeModules,
): BashOperations {
  return {
    async exec(command, cwd, { onData, signal, timeout }) {
      if (!existsSync(cwd)) {
        throw new Error(`Working directory does not exist: ${cwd}`);
      }

      const preparedCommand = runtime.prepareSandboxedCommand(command);
      const wrappedCommand =
        await runtime.sandboxManager.wrapWithSandbox(preparedCommand);
      const adjustedWrappedCommand =
        runtime.rewriteSandboxRuntimeLoopbackHosts(wrappedCommand);

      return new Promise((resolve, reject) => {
        const child = spawn("bash", ["-c", adjustedWrappedCommand], {
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

function getErrorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function blockedBashResult(message: string) {
  return {
    output: message,
    exitCode: 1,
    cancelled: false,
    truncated: false,
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
  let activationPromise: Promise<SandboxNotification | undefined> | undefined;

  function emitSandboxStateChanged(enabled: boolean): void {
    pi.events.emit("sandbox:state-changed", enabled);
  }

  async function disableSandboxForCurrentSession(): Promise<void> {
    if (!sandboxState.initialized) {
      sandboxState.enabled = false;
      return;
    }

    const runtime = await loadSandboxRuntime();
    await runtime.disableSandbox({
      state: sandboxState,
      reset: () => runtime.sandboxManager.reset(),
      emitStateChanged: emitSandboxStateChanged,
    });
  }

  async function enableSandboxForCurrentSession(ctx: {
    cwd: string;
  }): Promise<SandboxNotification | undefined> {
    if (sandboxState.initialized) return undefined;
    if (activationPromise) return activationPromise;

    const activate = (async (): Promise<SandboxNotification | undefined> => {
      const noSandbox = pi.getFlag("no-sandbox") as boolean;
      if (!settings.enabled) {
        await disableSandboxForCurrentSession();
        return {
          message: "Sandbox disabled via extension setting",
          type: "info",
        };
      }

      if (noSandbox) {
        await disableSandboxForCurrentSession();
        return {
          message: "Sandbox disabled via --no-sandbox",
          type: "warning",
        };
      }

      if (process.platform !== "darwin" && process.platform !== "linux") {
        await disableSandboxForCurrentSession();
        return {
          message: `Sandbox not supported on ${process.platform}`,
          type: "warning",
        };
      }

      try {
        const config = await loadSandboxConfig(ctx.cwd);
        if (!config.enabled) {
          await disableSandboxForCurrentSession();
          return {
            message: "Sandbox disabled via config",
            type: "info",
          };
        }

        const runtime = await loadSandboxRuntime();
        return await runtime.ensureSandboxActive({
          state: sandboxState,
          settingsEnabled: settings.enabled,
          noSandbox,
          platform: process.platform,
          cwd: ctx.cwd,
          loadConfig: () => config,
          initialize: async (sandboxConfig) => {
            await runtime.sandboxManager.initialize({
              network: sandboxConfig.network,
              filesystem: sandboxConfig.filesystem,
              ignoreViolations: sandboxConfig.ignoreViolations,
              enableWeakerNestedSandbox:
                sandboxConfig.enableWeakerNestedSandbox,
            });
          },
          reset: () => runtime.sandboxManager.reset(),
          emitStateChanged: emitSandboxStateChanged,
        });
      } catch (error) {
        return {
          message: `Sandbox initialization failed: ${getErrorMessage(error)}`,
          type: "error",
        };
      }
    })();

    activationPromise = activate.finally(() => {
      activationPromise = undefined;
    });
    return activationPromise;
  }

  async function applyEnabledSettingChange(
    enabled: boolean,
    ctx: { cwd: string },
  ): Promise<SandboxNotification | undefined> {
    settings.enabled = enabled;

    if (!enabled) {
      const pendingActivation = activationPromise;
      if (pendingActivation) await pendingActivation;
      await disableSandboxForCurrentSession();
      return undefined;
    }

    return enableSandboxForCurrentSession(ctx);
  }

  registerSandboxToggleCommand(pi, {
    settings,
    saveEnabled: saveSandboxEnabledSettings,
    applySettingChange: applyEnabledSettingChange,
  });

  pi.events.on(YOLO_SET_SANDBOX_ENABLED_EVENT, async (payload: unknown) => {
    const actual = readYoloToggleStateChangedEvent(payload);
    if (!actual) {
      return;
    }

    await applyEnabledSettingChange(actual.enabled, { cwd: actual.cwd });
  });

  pi.registerTool({
    ...localBash,
    label: "bash (sandboxed)",
    async execute(id, params, signal, onUpdate, ctx) {
      const notification = await enableSandboxForCurrentSession(ctx);
      if (notification?.type === "error") {
        throw new Error(notification.message);
      }

      if (!sandboxState.enabled || !sandboxState.initialized) {
        return localBash.execute(id, params, signal, onUpdate);
      }

      const runtime = await loadSandboxRuntime();
      const sandboxedBash = createBashTool(localCwd, {
        operations: createSandboxedBashOps(runtime),
      });
      return sandboxedBash.execute(id, params, signal, onUpdate);
    },
  });

  pi.on("user_bash", async (event) => {
    const notification = await enableSandboxForCurrentSession({
      cwd: event.cwd,
    });
    if (notification?.type === "error") {
      return { result: blockedBashResult(notification.message) };
    }

    if (!sandboxState.enabled || !sandboxState.initialized) return;

    try {
      const runtime = await loadSandboxRuntime();
      return { operations: createSandboxedBashOps(runtime) };
    } catch (error) {
      return {
        result: blockedBashResult(
          `Sandbox initialization failed: ${getErrorMessage(error)}`,
        ),
      };
    }
  });

  pi.on("session_shutdown", async () => {
    await disableSandboxForCurrentSession();
  });

  pi.registerCommand("cmd:sandbox", {
    description: "Show sandbox configuration",
    handler: async (_args, ctx) => {
      if (!settings.enabled) {
        ctx.ui.notify("Sandbox is disabled", "info");
        return;
      }

      if (pi.getFlag("no-sandbox") as boolean) {
        ctx.ui.notify("Sandbox is disabled via --no-sandbox", "warning");
        return;
      }

      let config: SandboxConfig;
      try {
        config = await loadSandboxConfig(ctx.cwd);
      } catch (error) {
        ctx.ui.notify(
          `Could not load sandbox configuration: ${getErrorMessage(error)}`,
          "error",
        );
        return;
      }

      if (!config.enabled) {
        ctx.ui.notify("Sandbox is disabled via config", "info");
        return;
      }

      const status = sandboxState.initialized
        ? "Sandbox Configuration:"
        : "Sandbox Configuration (enabled; pending first bash):";
      const lines = [
        status,
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
