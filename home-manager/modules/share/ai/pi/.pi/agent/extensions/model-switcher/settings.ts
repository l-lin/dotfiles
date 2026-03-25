import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

export interface ModelSelectorSettings {
  models: string[];
  keybind: string;
}

interface PiSettings {
  extensionSettings?: {
    modelSelector?: Partial<ModelSelectorSettings>;
    [key: string]: unknown;
  };
  [key: string]: unknown;
}

const DEFAULTS: ModelSelectorSettings = {
  models: [],
  keybind: "alt-m",
};

function getLegacySettingsPath(): string {
  return path.join(os.homedir(), ".pi", "agent", "settings.json");
}

function getXdgSettingsPath(): string {
  return process.env.XDG_CONFIG_HOME
    ? path.join(process.env.XDG_CONFIG_HOME, "pi", "agent", "settings.json")
    : getLegacySettingsPath();
}

function getSettingsPath(): string {
  const legacySettingsPath = getLegacySettingsPath();
  if (fs.existsSync(legacySettingsPath)) return legacySettingsPath;

  return getXdgSettingsPath();
}

function readSettingsFile(): PiSettings {
  try {
    return JSON.parse(
      fs.readFileSync(getSettingsPath(), "utf-8"),
    ) as PiSettings;
  } catch {
    return {};
  }
}

export function loadSettings(): ModelSelectorSettings {
  const settings = readSettingsFile();
  const parsed = settings.extensionSettings?.modelSelector ?? {};

  return {
    models: Array.isArray(parsed.models)
      ? parsed.models.filter(
          (model): model is string =>
            typeof model === "string" && model.trim().length > 0,
        )
      : [...DEFAULTS.models],
    keybind:
      typeof parsed.keybind === "string" && parsed.keybind.trim().length > 0
        ? parsed.keybind
        : DEFAULTS.keybind,
  };
}

export function saveSettings(settings: ModelSelectorSettings): void {
  const existing = readSettingsFile();
  const extensionSettings = (existing.extensionSettings ?? {}) as Record<
    string,
    unknown
  >;

  extensionSettings.modelSelector = {
    models: [...settings.models],
    keybind: settings.keybind,
  };
  existing.extensionSettings = extensionSettings;

  const settingsPath = getSettingsPath();
  fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
  fs.writeFileSync(settingsPath, JSON.stringify(existing, null, 2) + "\n");
}
