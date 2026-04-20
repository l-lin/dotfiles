/**
 * The damage-control extension provides real-time security hooks to prevent
 * catastrophic mistakes when agents execute bash commands or modify files.
 * It evaluates tool calls against `.pi/agent/damage-control-rules.yml`.
 *
 * Usage:
 * - `/damage-control-toggle` toggles the extension on or off.
 * - The toggle is persisted to `~/.pi/agent/settings.json`.
 * - The change is applied to the current session immediately.
 *
 * src: https://github.com/disler/pi-vs-claude-code/blob/46f15dbb09067fc3287b55949e93ed4d0625c4d2/extensions/damage-control.ts
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { parse as yamlParse } from "yaml";
import {
  loadDamageControlEnabledSettings,
  saveDamageControlEnabledSettings,
} from "./settings.js";
import {
  registerDamageControlToggleCommand,
  type DamageControlToggleNotification,
} from "./toggle-command.js";

const RULE_FILENAME = "damage-control-rules.yml";
const ICON = "";

interface Rule {
  pattern: string;
  reason: string;
}

interface Rules {
  bashToolPatterns: Rule[];
  zeroAccessPaths: string[];
  readOnlyPaths: string[];
  noDeletePaths: string[];
}

function createEmptyRules(): Rules {
  return {
    bashToolPatterns: [],
    zeroAccessPaths: [],
    readOnlyPaths: [],
    noDeletePaths: [],
  };
}

function normalizeRules(loaded: Partial<Rules> | undefined): Rules {
  return {
    bashToolPatterns: loaded?.bashToolPatterns ?? [],
    zeroAccessPaths: loaded?.zeroAccessPaths ?? [],
    readOnlyPaths: loaded?.readOnlyPaths ?? [],
    noDeletePaths: loaded?.noDeletePaths ?? [],
  };
}

function resolveRulesPath(cwd: string): string | null {
  const projectRulesPath = path.join(cwd, ".pi", "agent", RULE_FILENAME);
  const globalRulesPath = path.join(
    os.homedir(),
    ".pi",
    "agent",
    RULE_FILENAME,
  );

  if (fs.existsSync(projectRulesPath)) {
    return projectRulesPath;
  }

  if (fs.existsSync(globalRulesPath)) {
    return globalRulesPath;
  }

  return null;
}

function loadRules(cwd: string): {
  rules: Rules;
  notification?: DamageControlToggleNotification;
} {
  const rulesPath = resolveRulesPath(cwd);

  if (!rulesPath) {
    return {
      rules: createEmptyRules(),
      notification: {
        message: `${ICON} No damage-control rules found.`,
        type: "info",
      },
    };
  }

  try {
    const content = fs.readFileSync(rulesPath, "utf8");
    const parsed = yamlParse(content) as Partial<Rules>;

    return {
      rules: normalizeRules(parsed),
    };
  } catch (error) {
    return {
      rules: createEmptyRules(),
      notification: {
        message: `${ICON} Failed to load rules: ${error instanceof Error ? error.message : String(error)}`,
        type: "error",
      },
    };
  }
}

function resolvePath(targetPath: string, cwd: string): string {
  if (targetPath.startsWith("~")) {
    targetPath = path.join(os.homedir(), targetPath.slice(1));
  }

  return path.resolve(cwd, targetPath);
}

function isPathMatch(
  targetPath: string,
  pattern: string,
  cwd: string,
): boolean {
  const resolvedPattern = pattern.startsWith("~")
    ? path.join(os.homedir(), pattern.slice(1))
    : pattern;

  if (resolvedPattern.endsWith("/")) {
    const absolutePattern = path.isAbsolute(resolvedPattern)
      ? resolvedPattern
      : path.resolve(cwd, resolvedPattern);
    return targetPath.startsWith(absolutePattern);
  }

  const regexPattern = resolvedPattern
    .replace(/[.+^${}()|[\]\\]/g, "\\$&")
    .replace(/\*/g, ".*");

  const regex = new RegExp(
    `^${regexPattern}$|^${regexPattern}/|/${regexPattern}$|/${regexPattern}/`,
  );

  const relativePath = path.relative(cwd, targetPath);

  return (
    regex.test(targetPath) ||
    regex.test(relativePath) ||
    targetPath.includes(resolvedPattern) ||
    relativePath.includes(resolvedPattern)
  );
}

export default function (pi: ExtensionAPI) {
  const settings = loadDamageControlEnabledSettings();
  const runtimeState = {
    enabled: false,
  };
  let rules = createEmptyRules();

  function emitStateChanged(enabled: boolean): void {
    pi.events.emit("damage-control:state-changed", enabled);
  }

  function disableForCurrentSession(): void {
    rules = createEmptyRules();
    runtimeState.enabled = false;
    emitStateChanged(false);
  }

  function enableForCurrentSession(ctx: {
    cwd: string;
  }): DamageControlToggleNotification | undefined {
    const loaded = loadRules(ctx.cwd);
    rules = loaded.rules;
    runtimeState.enabled = true;
    emitStateChanged(true);
    return loaded.notification;
  }

  registerDamageControlToggleCommand(pi, {
    settings,
    saveEnabled: saveDamageControlEnabledSettings,
    applySettingChange: async (enabled, ctx) => {
      if (!enabled) {
        disableForCurrentSession();
        return undefined;
      }

      return enableForCurrentSession(ctx);
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    if (!settings.enabled) {
      disableForCurrentSession();
      return;
    }

    const notification = enableForCurrentSession({ cwd: ctx.cwd });
    if (notification) {
      ctx.ui.notify(notification.message, notification.type);
    }
  });

  pi.on("tool_call", async (event, ctx) => {
    if (!runtimeState.enabled) {
      return { block: false };
    }

    let violationReason: string | null = null;

    const checkPaths = (pathsToCheck: string[]) => {
      for (const pathToCheck of pathsToCheck) {
        const resolved = resolvePath(pathToCheck, ctx.cwd);
        for (const zeroAccessPath of rules.zeroAccessPaths) {
          if (isPathMatch(resolved, zeroAccessPath, ctx.cwd)) {
            return `Access to zero-access path restricted: ${zeroAccessPath}`;
          }
        }
      }
      return null;
    };

    const inputPaths: string[] = [];
    if (
      isToolCallEventType("read", event) ||
      isToolCallEventType("write", event) ||
      isToolCallEventType("edit", event)
    ) {
      inputPaths.push(event.input.path);
    } else if (
      isToolCallEventType("grep", event) ||
      isToolCallEventType("find", event) ||
      isToolCallEventType("ls", event)
    ) {
      inputPaths.push(event.input.path || ".");
    }

    if (isToolCallEventType("grep", event) && event.input.glob) {
      for (const zeroAccessPath of rules.zeroAccessPaths) {
        if (
          event.input.glob.includes(zeroAccessPath) ||
          isPathMatch(event.input.glob, zeroAccessPath, ctx.cwd)
        ) {
          violationReason = `Glob matches zero-access path: ${zeroAccessPath}`;
          break;
        }
      }
    }

    if (!violationReason) {
      violationReason = checkPaths(inputPaths);
    }

    if (!violationReason) {
      if (isToolCallEventType("bash", event)) {
        const command = event.input.command;

        for (const rule of rules.bashToolPatterns) {
          const regex = new RegExp(rule.pattern);
          if (regex.test(command)) {
            violationReason = rule.reason;
            break;
          }
        }

        if (!violationReason) {
          for (const zeroAccessPath of rules.zeroAccessPaths) {
            if (command.includes(zeroAccessPath)) {
              violationReason = `Bash command references zero-access path: ${zeroAccessPath}`;
              break;
            }
          }
        }

        if (!violationReason) {
          for (const readOnlyPath of rules.readOnlyPaths) {
            if (
              command.includes(readOnlyPath) &&
              (/[\s>|]/.test(command) ||
                command.includes("rm") ||
                command.includes("mv") ||
                command.includes("sed"))
            ) {
              violationReason = `Bash command may modify read-only path: ${readOnlyPath}`;
              break;
            }
          }
        }

        if (!violationReason) {
          for (const noDeletePath of rules.noDeletePaths) {
            if (
              command.includes(noDeletePath) &&
              (command.includes("rm") || command.includes("mv"))
            ) {
              violationReason = `Bash command attempts to delete/move protected path: ${noDeletePath}`;
              break;
            }
          }
        }
      } else if (
        isToolCallEventType("write", event) ||
        isToolCallEventType("edit", event)
      ) {
        for (const pathToCheck of inputPaths) {
          const resolved = resolvePath(pathToCheck, ctx.cwd);
          for (const readOnlyPath of rules.readOnlyPaths) {
            if (isPathMatch(resolved, readOnlyPath, ctx.cwd)) {
              violationReason = `Modification of read-only path restricted: ${readOnlyPath}`;
              break;
            }
          }
        }
      }
    }

    if (violationReason) {
      const blockedReasonBase = `${ICON} BLOCKED: ${violationReason}`;

      if (!ctx.hasUI) {
        pi.appendEntry("damage-control-log", {
          tool: event.toolName,
          input: event.input,
          rule: violationReason,
          action: "blocked",
        });
        ctx.abort();
        return {
          block: true,
          reason: `${blockedReasonBase} (User approval required, but UI is unavailable)\n\nDO NOT attempt to work around this restriction. DO NOT retry with alternative commands, paths, or approaches that achieve the same result. Report this block to the user exactly as stated and ask how they would like to proceed.`,
        };
      }

      const inputSummary = isToolCallEventType("bash", event)
        ? `Command: ${event.input.command}`
        : `Input: ${JSON.stringify(event.input, null, 2)}`;
      const confirmed = await ctx.ui.confirm(
        `${ICON} Permission required`,
        `Damage-control flagged this ${event.toolName} call: ${violationReason}\n\n${inputSummary}\n\nAllow it to continue?`,
        { timeout: 30000 },
      );

      if (!confirmed) {
        ctx.ui.notify(`⚠️ Violation Blocked: ${violationReason}`);
        pi.appendEntry("damage-control-log", {
          tool: event.toolName,
          input: event.input,
          rule: violationReason,
          action: "blocked_by_user",
        });
        ctx.abort();
        return {
          block: true,
          reason: `${blockedReasonBase} (User denied)\n\nDO NOT attempt to work around this restriction. DO NOT retry with alternative commands, paths, or approaches that achieve the same result. Report this block to the user exactly as stated and ask how they would like to proceed.`,
        };
      }

      pi.appendEntry("damage-control-log", {
        tool: event.toolName,
        input: event.input,
        rule: violationReason,
        action: "confirmed_by_user",
      });
      return { block: false };
    }

    return { block: false };
  });
}
