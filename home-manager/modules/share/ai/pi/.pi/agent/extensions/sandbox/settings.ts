import {
  loadEnabledSettings,
  saveExtensionSettings,
  type EnabledSettings,
} from "../tool-settings/index.js";

export type SandboxEnabledSettings = EnabledSettings;

export const SANDBOX_SETTINGS_KEY = "sandbox";
export const DEFAULT_SANDBOX_ENABLED_SETTINGS: SandboxEnabledSettings = {
  enabled: true,
};

export function loadSandboxEnabledSettings(
  defaults: SandboxEnabledSettings = DEFAULT_SANDBOX_ENABLED_SETTINGS,
): SandboxEnabledSettings {
  return loadEnabledSettings(SANDBOX_SETTINGS_KEY, defaults);
}

export function saveSandboxEnabledSettings(enabled: boolean): void {
  saveExtensionSettings({
    extensionKey: SANDBOX_SETTINGS_KEY,
    enabled,
  });
}
