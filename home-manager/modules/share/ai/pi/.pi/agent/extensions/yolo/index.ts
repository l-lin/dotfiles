/**
 * Yolo extension - Toggle sandbox and damage-control together.
 *
 * Dependencies:
 * - ../damage-control/
 * - ../sandbox/
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  DAMAGE_CONTROL_SETTINGS_KEY,
  loadDamageControlEnabledSettings,
} from "../damage-control/settings.js";
import {
  loadSandboxEnabledSettings,
  SANDBOX_SETTINGS_KEY,
} from "../sandbox/settings.js";
import { saveExtensionSettingsPatches } from "../tool-settings/index.js";
import {
  YOLO_SET_DAMAGE_CONTROL_ENABLED_EVENT,
  YOLO_SET_SANDBOX_ENABLED_EVENT,
} from "./events.js";

export const YOLO_TOGGLE_COMMAND = "cmd:yolo-toggle";

export default function (
  pi: Pick<ExtensionAPI, "registerCommand" | "events">,
): void {
  pi.registerCommand(YOLO_TOGGLE_COMMAND, {
    description: "Toggle sandbox and damage-control together",
    handler: async (_commandArgs, ctx) => {
      const sandboxSettings = loadSandboxEnabledSettings();
      const damageControlSettings = loadDamageControlEnabledSettings();
      const currentEnabled = sandboxSettings.enabled;
      const nextEnabled = !currentEnabled;

      saveExtensionSettingsPatches([
        {
          extensionKey: SANDBOX_SETTINGS_KEY,
          patch: { enabled: nextEnabled },
        },
        {
          extensionKey: DAMAGE_CONTROL_SETTINGS_KEY,
          patch: { enabled: nextEnabled },
        },
      ]);

      sandboxSettings.enabled = nextEnabled;
      damageControlSettings.enabled = nextEnabled;

      pi.events.emit(YOLO_SET_SANDBOX_ENABLED_EVENT, {
        enabled: nextEnabled,
        cwd: ctx.cwd,
      });
      pi.events.emit(YOLO_SET_DAMAGE_CONTROL_ENABLED_EVENT, {
        enabled: nextEnabled,
        cwd: ctx.cwd,
      });

      ctx.ui.notify(
        `Sandbox and damage-control ${nextEnabled ? "enabled" : "disabled"}`,
        "info",
      );
    },
  });
}
