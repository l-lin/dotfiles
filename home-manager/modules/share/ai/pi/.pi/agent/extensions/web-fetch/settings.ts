import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

export interface WebFetchSettings {
  enabled: boolean;
}

const DEFAULTS: WebFetchSettings = { enabled: true };
const SETTINGS_PATH = path.join(os.homedir(), ".pi", "agent", "settings.json");

export function loadSettings(): WebFetchSettings {
  try {
    const raw = fs.readFileSync(SETTINGS_PATH, "utf-8");
    const settings = JSON.parse(raw) as {
      extensionSettings?: { webFetch?: Partial<WebFetchSettings> };
    };
    const parsed = settings.extensionSettings?.webFetch ?? {};
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
  const existing = (extensionSettings.webFetch ?? {}) as Record<
    string,
    unknown
  >;
  extensionSettings.webFetch = { ...existing, enabled };
  settings.extensionSettings = extensionSettings;
  fs.mkdirSync(path.dirname(SETTINGS_PATH), { recursive: true });
  fs.writeFileSync(
    SETTINGS_PATH,
    JSON.stringify(settings, null, 2) + "\n",
    "utf-8",
  );
}
