import {
  loadEnabledSettings,
  saveExtensionSettings,
  type EnabledSettings,
} from "../tool-settings/index.js";

export type DamageControlEnabledSettings = EnabledSettings;

export const DAMAGE_CONTROL_SETTINGS_KEY = "damageControl";
export const DEFAULT_DAMAGE_CONTROL_ENABLED_SETTINGS: DamageControlEnabledSettings =
  {
    enabled: true,
  };

export function loadDamageControlEnabledSettings(
  defaults: DamageControlEnabledSettings = DEFAULT_DAMAGE_CONTROL_ENABLED_SETTINGS,
): DamageControlEnabledSettings {
  return loadEnabledSettings(DAMAGE_CONTROL_SETTINGS_KEY, defaults);
}

export function saveDamageControlEnabledSettings(enabled: boolean): void {
  saveExtensionSettings({
    extensionKey: DAMAGE_CONTROL_SETTINGS_KEY,
    enabled,
  });
}
