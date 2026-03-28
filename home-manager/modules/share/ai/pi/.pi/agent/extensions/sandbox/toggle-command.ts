import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import type { SandboxEnabledSettings } from "./settings.js";

export interface SandboxCommandContext {
  cwd: string;
  ui: {
    notify: (message: string, type?: string) => void;
  };
}

export interface SandboxToggleNotification {
  message: string;
  type: "info" | "warning" | "error";
}

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
  pi: Pick<ExtensionAPI, "registerCommand">,
  args: RegisterSandboxToggleCommandArgs,
): void {
  pi.registerCommand(SANDBOX_TOGGLE_COMMAND, {
    description: "Toggle sandbox extension on/off",
    handler: async (_commandArgs, ctx) => {
      const nextEnabled = !args.settings.enabled;
      args.saveEnabled(nextEnabled);
      args.settings.enabled = nextEnabled;

      const notification = await args.applySettingChange?.(
        nextEnabled,
        ctx as SandboxCommandContext,
      );

      const message =
        notification?.message ??
        `Sandbox ${nextEnabled ? "enabled" : "disabled"}`;

      ctx.ui.notify(message, notification?.type ?? "info");
    },
  });
}
