import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  registerExtensionToggleCommand,
  type ToggleCommandNotification,
} from "../tool-settings/index.js";
import type { DamageControlEnabledSettings } from "./settings.js";

export interface DamageControlCommandContext {
  cwd: string;
  ui: {
    notify: (message: string, type?: string) => void;
  };
}

export type DamageControlToggleNotification = ToggleCommandNotification;

export interface RegisterDamageControlToggleCommandArgs {
  settings: DamageControlEnabledSettings;
  saveEnabled: (enabled: boolean) => void;
  applySettingChange?: (
    enabled: boolean,
    ctx: DamageControlCommandContext,
  ) =>
    | Promise<DamageControlToggleNotification | undefined | void>
    | DamageControlToggleNotification
    | undefined
    | void;
}

export const DAMAGE_CONTROL_TOGGLE_COMMAND = "cmd:damage-control-toggle";

export function registerDamageControlToggleCommand(
  pi: Pick<
    ExtensionAPI,
    "registerCommand" | "getActiveTools" | "setActiveTools" | "events"
  >,
  args: RegisterDamageControlToggleCommandArgs,
): void {
  registerExtensionToggleCommand(pi, {
    commandName: DAMAGE_CONTROL_TOGGLE_COMMAND,
    description: "Toggle damage-control extension on/off",
    label: "Damage control",
    settings: args.settings,
    saveEnabled: args.saveEnabled,
    applyEnabledState(enabled, ctx) {
      return args.applySettingChange?.(
        enabled,
        ctx as DamageControlCommandContext,
      );
    },
  });
}
