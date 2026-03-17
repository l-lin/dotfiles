/** Reads ~/.pi/agent/settings.json (extensionSettings.askUserQuestion property) to provide configurable defaults. */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

export interface AskUserQuestionSettings {
  /** Whether the ask-user-question tool is enabled. Default: true. */
  enabled: boolean;
}

const DEFAULTS: AskUserQuestionSettings = { enabled: true };

const SETTINGS_PATH = path.join(os.homedir(), ".pi", "agent", "settings.json");

/** Loads settings from disk. Falls back to defaults on any error. */
export function loadSettings(): AskUserQuestionSettings {
  try {
    const raw = fs.readFileSync(SETTINGS_PATH, "utf-8");
    const settings = JSON.parse(raw) as {
      extensionSettings?: {
        askUserQuestion?: Partial<AskUserQuestionSettings>;
      };
    };
    const parsed = settings.extensionSettings?.askUserQuestion ?? {};
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
  const existing = (extensionSettings.askUserQuestion ?? {}) as Record<
    string,
    unknown
  >;
  extensionSettings.askUserQuestion = { ...existing, enabled };
  settings.extensionSettings = extensionSettings;
  fs.mkdirSync(path.dirname(SETTINGS_PATH), { recursive: true });
  try {
    fs.writeFileSync(
      SETTINGS_PATH,
      JSON.stringify(settings, null, 2) + "\n",
      "utf-8",
    );
  } catch (err) {
    throw new Error(
      `ask-user-question: failed to save settings to ${SETTINGS_PATH}: ${(err as Error).message}`,
    );
  }
}
