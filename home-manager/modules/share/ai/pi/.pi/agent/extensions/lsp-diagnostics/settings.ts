/** Reads ~/.pi/agent/settings.json (extensionSettings.lspDiagnostics property) to provide configurable defaults. */

import {
  loadEnabledSettings,
  saveExtensionSettings,
} from "../tool-settings/index.js";

export interface LspDiagnosticsSettings {
  /** Whether the lsp_get_diagnostics tool is registered. Default: true. */
  enabled: boolean;
}

const DEFAULTS: LspDiagnosticsSettings = {
  enabled: true,
};

const SETTINGS_KEY = "lspDiagnostics";

/** Loads settings from disk once at startup. */
export function loadSettings(): LspDiagnosticsSettings {
  return loadEnabledSettings(SETTINGS_KEY, DEFAULTS);
}

/** Persists a single field into settings.json, preserving all other keys. */
export function saveEnabled(enabled: boolean): void {
  saveExtensionSettings({
    extensionKey: SETTINGS_KEY,
    enabled,
  });
}
