// ============================================================================
// GitHub Copilot Extension — Settings Persistence
// ============================================================================

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import type { CopilotUsageSettings, PiSettings } from "./types.js";

// Respect XDG_CONFIG_HOME, consistent with auth.ts and pi's own config resolution.
const PI_CONFIG_DIR = process.env.XDG_CONFIG_HOME
  ? path.join(process.env.XDG_CONFIG_HOME, "pi")
  : path.join(os.homedir(), ".pi");
const SETTINGS_PATH = path.join(PI_CONFIG_DIR, "agent/settings.json");

export function loadSettings(): CopilotUsageSettings {
  try {
    if (fs.existsSync(SETTINGS_PATH)) {
      const content = fs.readFileSync(SETTINGS_PATH, "utf-8");
      const parsed = JSON.parse(content) as PiSettings;
      return parsed.extensionSettings?.copilotUsage ?? {};
    }
  } catch {
    // Ignore errors, return defaults
  }
  return {};
}

export function saveSettings(settings: CopilotUsageSettings): void {
  try {
    let existing: PiSettings = {};
    if (fs.existsSync(SETTINGS_PATH)) {
      const content = fs.readFileSync(SETTINGS_PATH, "utf-8");
      existing = JSON.parse(content) as PiSettings;
    }
    existing.extensionSettings = {
      ...existing.extensionSettings,
      copilotUsage: settings,
    };
    fs.mkdirSync(path.dirname(SETTINGS_PATH), { recursive: true });
    fs.writeFileSync(SETTINGS_PATH, JSON.stringify(existing, null, 2), "utf-8");
  } catch {
    // Ignore write errors silently
  }
}
