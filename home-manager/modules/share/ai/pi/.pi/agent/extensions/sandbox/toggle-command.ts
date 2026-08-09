import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  registerExtensionToggleCommand,
  type ToggleCommandNotification,
} from "../tool-settings/index.js";
import type { SandboxEnabledSettings } from "./settings.js";

export interface SandboxCommandContext {
  cwd: string;
  ui: {
    notify: (message: string, type?: string) => void;
  };
}

export type SandboxToggleNotification = ToggleCommandNotification;

export interface RegisterSandboxToggleCommandArgs {
  settings: SandboxEnabledSettings;
  saveEnabled: (enabled: boolean) => void;
  applySettingChange?: (
    enabled: boolean,
    ctx: SandboxCommandContext,
  ) =>
    | Promise<SandboxToggleNotification | undefined | void>
    | SandboxToggleNotification
    | undefined
    | void;
}

export const SANDBOX_TOGGLE_COMMAND = "cmd:sandbox-toggle";

export function registerSandboxToggleCommand(
  pi: Pick<
    ExtensionAPI,
    "registerCommand" | "getActiveTools" | "setActiveTools" | "events"
  >,
  args: RegisterSandboxToggleCommandArgs,
): void {
  registerExtensionToggleCommand(pi, {
    commandName: SANDBOX_TOGGLE_COMMAND,
    description: "Toggle sandbox extension on/off",
    label: "Sandbox",
    settings: args.settings,
    saveEnabled: args.saveEnabled,
    applyEnabledState(enabled, ctx) {
      return args.applySettingChange?.(enabled, ctx as SandboxCommandContext);
    },
  });
}
