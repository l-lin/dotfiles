import {
  readExtensionSettings,
  saveExtensionSettingsPatch,
} from "../tool-settings/index.js";

export type AwesomeEditorMode = "vi" | "emacs";

export type AwesomeEditorSettings = {
  mode: AwesomeEditorMode;
};

export const AWESOME_EDITOR_SETTINGS_KEY = "awesomeEditor";
export const DEFAULT_AWESOME_EDITOR_SETTINGS: AwesomeEditorSettings = {
  mode: "emacs",
};

export function isAwesomeEditorMode(
  value: unknown,
): value is AwesomeEditorMode {
  return value === "vi" || value === "emacs";
}

export function loadAwesomeEditorSettings(
  defaults: AwesomeEditorSettings = DEFAULT_AWESOME_EDITOR_SETTINGS,
): AwesomeEditorSettings {
  const parsed = readExtensionSettings<Partial<AwesomeEditorSettings>>(
    AWESOME_EDITOR_SETTINGS_KEY,
  );

  return {
    ...defaults,
    mode: isAwesomeEditorMode(parsed.mode) ? parsed.mode : defaults.mode,
  };
}

export function saveAwesomeEditorMode(mode: AwesomeEditorMode): void {
  saveExtensionSettingsPatch<AwesomeEditorSettings>({
    extensionKey: AWESOME_EDITOR_SETTINGS_KEY,
    patch: { mode },
  });
}
