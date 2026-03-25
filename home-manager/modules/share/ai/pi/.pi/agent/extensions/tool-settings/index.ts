/** Shared helpers for tool enablement state. */

import { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export type ToggleToolsArgs = {
  toolName: string;
  enabled: boolean;
};

export type EnabledSettings = {
  enabled: boolean;
};

export type RegisterEnabledToggleCommandArgs = {
  toolName: string;
  description: string;
  settings: EnabledSettings;
  saveEnabled: (enabled: boolean) => void;
};

export function updateActiveTools(pi: ExtensionAPI, args: ToggleToolsArgs) {
  const current = pi.getActiveTools();
  let updated: string[];
  if (args.enabled) {
    updated = current.includes(args.toolName)
      ? current
      : [...current, args.toolName];
  } else {
    updated = current.filter((t) => t !== args.toolName);
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
      args.saveEnabled(nextEnabled);
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

export default function (_pi: ExtensionAPI) {}
