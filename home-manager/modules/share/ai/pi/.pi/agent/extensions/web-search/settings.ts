import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

const SETTINGS_PATH = path.join(os.homedir(), ".pi", "agent", "settings.json");

export interface WebSearchSettings {
  enabled: boolean;
}

const DEFAULTS: WebSearchSettings = { enabled: true };

export function loadSettings(): WebSearchSettings {
  try {
    const raw = fs.readFileSync(SETTINGS_PATH, "utf-8");
    const settings = JSON.parse(raw) as {
      extensionSettings?: { webSearch?: Partial<WebSearchSettings> };
    };
    const parsed = settings.extensionSettings?.webSearch ?? {};
    return {
      enabled:
        typeof parsed.enabled === "boolean" ? parsed.enabled : DEFAULTS.enabled,
    };
  } catch {
    return { ...DEFAULTS };
  }
}

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
  const existing = (extensionSettings.webSearch ?? {}) as Record<
    string,
    unknown
  >;
  extensionSettings.webSearch = { ...existing, enabled };
  settings.extensionSettings = extensionSettings;
  fs.mkdirSync(path.dirname(SETTINGS_PATH), { recursive: true });
  fs.writeFileSync(
    SETTINGS_PATH,
    JSON.stringify(settings, null, 2) + "\n",
    "utf-8",
  );
}
