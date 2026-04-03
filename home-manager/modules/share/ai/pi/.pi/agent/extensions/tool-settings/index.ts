/** Shared helpers for tool enablement state and persisted settings. */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export type ToggleToolsArgs = {
  toolName: string;
  enabled: boolean;
};

export type EnabledSettings = {
  enabled: boolean;
};

export type RegisterEnabledToggleCommandArgs = {
  toolName: string;
  extensionKey: string;
  description: string;
  settings: EnabledSettings;
};

export type SaveExtensionSettingsArgs = {
  extensionKey: string;
  enabled: boolean;
};

type PiSettings = Record<string, unknown> & {
  extensionSettings?: Record<string, unknown>;
};

export function getAgentSettingsPath(): string {
  return path.join(os.homedir(), ".pi", "agent", "settings.json");
}

export function updateActiveTools(
  pi: ExtensionAPI,
  args: ToggleToolsArgs,
): void {
  const current = pi.getActiveTools();
  let updated: string[];

  if (args.enabled) {
    updated = current.includes(args.toolName)
      ? current
      : [...current, args.toolName];
  } else {
    updated = current.filter((toolName) => toolName !== args.toolName);
  }

  pi.setActiveTools(updated);
}

export function registerEnabledToggleCommand(
  pi: ExtensionAPI,
  args: RegisterEnabledToggleCommandArgs,
): void {
  const commandName = `cmd:${args.toolName}-toggle`;

  pi.registerCommand(commandName, {
    description: args.description,
    handler: async (_commandArgs, ctx) => {
      const nextEnabled = !args.settings.enabled;
      saveExtensionSettings({
        extensionKey: args.extensionKey,
        enabled: nextEnabled,
      });
      args.settings.enabled = nextEnabled;

      updateActiveTools(pi, {
        toolName: args.toolName,
        enabled: nextEnabled,
      });
      pi.events.emit("custom-tool:changed", {
        tool: args.toolName,
        enabled: nextEnabled,
      });

      ctx.ui.notify(
        `${args.toolName} ${nextEnabled ? "enabled" : "disabled"}`,
        "info",
      );
    },
  });
}

export function readExtensionSettings<T extends object>(
  extensionKey: string,
): Partial<T> {
  const settings = readSettingsFile();
  const extensionSettings = isRecord(settings.extensionSettings)
    ? settings.extensionSettings
    : undefined;
  const extensionValue = extensionSettings?.[extensionKey];

  return isRecord(extensionValue) ? (extensionValue as Partial<T>) : {};
}

export function loadEnabledSettings<T extends EnabledSettings>(
  extensionKey: string,
  defaults: T,
): T {
  const parsed = readExtensionSettings<T>(extensionKey);

  return {
    ...defaults,
    enabled:
      typeof parsed.enabled === "boolean" ? parsed.enabled : defaults.enabled,
  };
}

export function saveExtensionSettings(args: SaveExtensionSettingsArgs): void {
  const settings = readSettingsFile();
  const extensionSettings = isRecord(settings.extensionSettings)
    ? { ...settings.extensionSettings }
    : {};
  const existingSettings = isRecord(extensionSettings[args.extensionKey])
    ? (extensionSettings[args.extensionKey] as Record<string, unknown>)
    : {};

  extensionSettings[args.extensionKey] = {
    ...existingSettings,
    enabled: args.enabled,
  };
  settings.extensionSettings = extensionSettings;

  writeSettingsFile(settings);
}

function readSettingsFile(): PiSettings {
  try {
    const raw = fs.readFileSync(getAgentSettingsPath(), "utf-8");
    const parsed = JSON.parse(raw) as unknown;
    return isRecord(parsed) ? (parsed as PiSettings) : {};
  } catch {
    return {};
  }
}

function writeSettingsFile(settings: PiSettings): void {
  const settingsPath = getAgentSettingsPath();
  fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
  fs.writeFileSync(
    settingsPath,
    JSON.stringify(settings, null, 2) + "\n",
    "utf-8",
  );
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export default function (_pi: ExtensionAPI) {}
