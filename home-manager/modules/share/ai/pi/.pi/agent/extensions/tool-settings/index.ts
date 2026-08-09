/** Shared helpers for tool enablement state and persisted settings. */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export type ToggleToolsArgs = {
  toolName: string;
  enabled: boolean;
};

export type EnabledSettings = {
  enabled: boolean;
};

export type ToggleCommandContext = {
  cwd?: string;
  ui: {
    notify: (message: string, type?: string) => void;
  };
};

export type ToggleCommandNotification = {
  message: string;
  type: "info" | "warning" | "error";
};

export type RegisterExtensionToggleCommandArgs = {
  commandName: string;
  description: string;
  label: string;
  settings: EnabledSettings;
  saveEnabled: (enabled: boolean) => void;
  applyEnabledState?: (
    enabled: boolean,
    ctx: ToggleCommandContext,
    pi: Pick<ExtensionAPI, "getActiveTools" | "setActiveTools" | "events">,
  ) =>
    | Promise<ToggleCommandNotification | undefined | void>
    | ToggleCommandNotification
    | undefined
    | void;
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

export type SaveExtensionSettingsPatchArgs<
  T extends object = Record<string, unknown>,
> = {
  extensionKey: string;
  patch: Partial<T>;
};

export type SaveExtensionSettingsPatchesArgs = Array<
  SaveExtensionSettingsPatchArgs<Record<string, unknown>>
>;

type PiSettings = Record<string, unknown> & {
  extensionSettings?: Record<string, unknown>;
};

export function getAgentSettingsPath(): string {
  return path.join(os.homedir(), ".pi", "agent", "settings.json");
}

export function updateActiveTools(
  pi: Pick<ExtensionAPI, "getActiveTools" | "setActiveTools">,
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

export function registerExtensionToggleCommand(
  pi: Pick<
    ExtensionAPI,
    "registerCommand" | "getActiveTools" | "setActiveTools" | "events"
  >,
  args: RegisterExtensionToggleCommandArgs,
): void {
  pi.registerCommand(args.commandName, {
    description: args.description,
    handler: async (_commandArgs, ctx) => {
      const nextEnabled = !args.settings.enabled;
      args.saveEnabled(nextEnabled);
      args.settings.enabled = nextEnabled;

      const notification = await args.applyEnabledState?.(
        nextEnabled,
        ctx as ToggleCommandContext,
        pi,
      );

      const message =
        notification?.message ??
        `${args.label} ${nextEnabled ? "enabled" : "disabled"}`;

      ctx.ui.notify(message, notification?.type ?? "info");
    },
  });
}

export function registerEnabledToggleCommand(
  pi: Pick<
    ExtensionAPI,
    "registerCommand" | "getActiveTools" | "setActiveTools" | "events"
  >,
  args: RegisterEnabledToggleCommandArgs,
): void {
  registerExtensionToggleCommand(pi, {
    commandName: `cmd:${args.toolName}-toggle`,
    description: args.description,
    label: args.toolName,
    settings: args.settings,
    saveEnabled(enabled) {
      saveExtensionSettings({
        extensionKey: args.extensionKey,
        enabled,
      });
    },
    applyEnabledState(enabled, _ctx, commandPi) {
      updateActiveTools(commandPi, {
        toolName: args.toolName,
        enabled,
      });
      commandPi.events.emit("custom-tool:changed", {
        tool: args.toolName,
        enabled,
      });
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

export function saveExtensionSettingsPatch<
  T extends object = Record<string, unknown>,
>(args: SaveExtensionSettingsPatchArgs<T>): void {
  saveExtensionSettingsPatches([args as SaveExtensionSettingsPatchArgs]);
}

export function saveExtensionSettingsPatches(
  args: SaveExtensionSettingsPatchesArgs,
): void {
  const settings = readSettingsFile();
  const extensionSettings = isRecord(settings.extensionSettings)
    ? { ...settings.extensionSettings }
    : {};

  for (const patchArgs of args) {
    const existingSettings = isRecord(extensionSettings[patchArgs.extensionKey])
      ? (extensionSettings[patchArgs.extensionKey] as Record<string, unknown>)
      : {};

    extensionSettings[patchArgs.extensionKey] = {
      ...existingSettings,
      ...patchArgs.patch,
    };
  }

  settings.extensionSettings = extensionSettings;
  writeSettingsFile(settings);
}

export function saveExtensionSettings(args: SaveExtensionSettingsArgs): void {
  saveExtensionSettingsPatch<EnabledSettings>({
    extensionKey: args.extensionKey,
    patch: { enabled: args.enabled },
  });
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
