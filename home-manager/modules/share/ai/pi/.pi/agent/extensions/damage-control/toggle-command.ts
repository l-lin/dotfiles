import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import type { DamageControlEnabledSettings } from "./settings.js";

export interface DamageControlCommandContext {
  cwd: string;
  ui: {
    notify: (message: string, type?: string) => void;
  };
}

export interface DamageControlToggleNotification {
  message: string;
  type: "info" | "warning" | "error";
}

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
  pi: Pick<ExtensionAPI, "registerCommand">,
  args: RegisterDamageControlToggleCommandArgs,
): void {
  pi.registerCommand(DAMAGE_CONTROL_TOGGLE_COMMAND, {
    description: "Toggle damage-control extension on/off",
    handler: async (_commandArgs, ctx) => {
      const nextEnabled = !args.settings.enabled;
      args.saveEnabled(nextEnabled);
      args.settings.enabled = nextEnabled;

      const notification = await args.applySettingChange?.(
        nextEnabled,
        ctx as DamageControlCommandContext,
      );

      const message =
        notification?.message ??
        `Damage control ${nextEnabled ? "enabled" : "disabled"}`;

      ctx.ui.notify(message, notification?.type ?? "info");
    },
  });
}
