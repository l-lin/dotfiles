import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

export interface ModelSelectorSettings {
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
    keybind:
      typeof parsed.keybind === "string" && parsed.keybind.trim().length > 0
        ? parsed.keybind
        : DEFAULTS.keybind,
  };
}
