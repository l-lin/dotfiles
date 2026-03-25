/** Reads ~/.pi/agent/settings.json (extensionSettings.lspDiagnostics property) to provide configurable defaults. */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

export interface LspDiagnosticsSettings {
  /** Whether the lsp_get_diagnostics tool is registered. Default: true. */
  enabled: boolean;
}

const DEFAULTS: LspDiagnosticsSettings = {
  enabled: true,
};

const SETTINGS_PATH = path.join(os.homedir(), ".pi", "agent", "settings.json");

/** Persists a single field into settings.json, preserving all other keys. */
export function saveEnabled(enabled: boolean): void {
  let settings: Record<string, unknown> = {};
  try {
    settings = JSON.parse(fs.readFileSync(SETTINGS_PATH, "utf-8"));
  } catch {
    // File missing or malformed — start fresh
  }
  const extensionSettings = (settings.extensionSettings ?? {}) as Record<
    string,
    unknown
  >;
  const existing = (extensionSettings.lspDiagnostics ?? {}) as Record<
    string,
    unknown
  >;
  extensionSettings.lspDiagnostics = { ...existing, enabled };
  settings.extensionSettings = extensionSettings;
  fs.mkdirSync(path.dirname(SETTINGS_PATH), { recursive: true });
  fs.writeFileSync(
    SETTINGS_PATH,
    JSON.stringify(settings, null, 2) + "\n",
    "utf-8",
  );
}

/** Loads settings from disk once at startup. */
export function loadSettings(): LspDiagnosticsSettings {
  try {
    const raw = fs.readFileSync(SETTINGS_PATH, "utf-8");
    const settings = JSON.parse(raw) as {
      extensionSettings?: { lspDiagnostics?: Partial<LspDiagnosticsSettings> };
    };
    const parsed = settings.extensionSettings?.lspDiagnostics ?? {};
    return {
      enabled:
        typeof parsed.enabled === "boolean" ? parsed.enabled : DEFAULTS.enabled,
    };
  } catch {
    // File missing or malformed — fall back to defaults silently
    return { ...DEFAULTS };
  }
}
