import * as fs from "node:fs";
import * as path from "node:path";
import { isDeepStrictEqual } from "node:util";
import {
  getAgentSettingsPath,
  readExtensionSettings,
  saveExtensionSettingsPatch,
} from "../tool-settings/index.js";

export const EXTENSION_KEY = "verdict";

export const DEFAULT_CLASSIFIER = "verdict-local/kev";

export interface VerdictSettings {
  enabled: boolean;
  debug: boolean;
  allow: string[];
  deny: string[];
  denyPaths: string[];
  ignoreTools: string[];
  builtinDenyFloor: boolean;
  classifierModel: string | null;
  audit: boolean;
  auditRedactSecrets: boolean;
  notifyAllows: boolean;
  classifierMinConfidence: number | null;
  classifierFallbackModel: string | null;
  classifierFallbackMode: "shadow" | "enforce";
  codemodeNestedCalls: "gate" | "rules-only";
}

export type UserRules = Omit<VerdictSettings, "enabled" | "allow" | "deny"> & {
  allow: RegExp[];
  deny: RegExp[];
};

export const DEFAULT_SETTINGS: VerdictSettings = {
  enabled: true,
  debug: true,
  allow: [],
  deny: [],
  denyPaths: [
    "~/.ssh/",
    "~/.profile",
    "~/.gnupg",
    "~/.mc",
    "~/.zshrc",
    "~/.bashrc",
    "~/.aws/config",
  ],
  ignoreTools: ["ask-user-question"],
  builtinDenyFloor: true,
  classifierModel: null,
  audit: false,
  auditRedactSecrets: true,
  notifyAllows: false,
  classifierMinConfidence: null,
  classifierFallbackModel: null,
  classifierFallbackMode: "enforce",
  codemodeNestedCalls: "gate",
};

export function agentDirPath(): string {
  return path.dirname(getAgentSettingsPath());
}

export function loadUserRules(): {
  rules: UserRules;
  enabled: boolean;
  skipped: string[];
} {
  const raw = readExtensionSettings<VerdictSettings>(EXTENSION_KEY);
  const skipped: string[] = [];
  const strings = (
    key: "allow" | "deny" | "denyPaths" | "ignoreTools",
  ): string[] => {
    const value = raw[key] ?? DEFAULT_SETTINGS[key];

    if (!Array.isArray(value)) {
      skipped.push(`${key}: expected an array`);

      return [...DEFAULT_SETTINGS[key]];
    }

    return value.flatMap((entry: unknown) => {
      if (typeof entry === "string" && entry.trim()) {
        return [entry.trim()];
      }

      skipped.push(`${key}: ${JSON.stringify(entry)}`);

      return [];
    });
  };
  const compile = (key: "allow" | "deny"): RegExp[] =>
    strings(key).flatMap((source) => {
      try {
        return [new RegExp(source)];
      } catch {
        skipped.push(`${key}: invalid expression ${source}`);

        return [];
      }
    });
  const boolean = (
    key:
      | "enabled"
      | "debug"
      | "builtinDenyFloor"
      | "audit"
      | "auditRedactSecrets"
      | "notifyAllows",
  ): boolean => {
    const value = raw[key];

    if (typeof value === "boolean") {
      return value;
    }

    if (value !== undefined) {
      skipped.push(`${key}: ${JSON.stringify(value)}; expected a boolean`);
    }

    return DEFAULT_SETTINGS[key];
  };
  const model = (
    key: "classifierModel" | "classifierFallbackModel",
  ): string | null => {
    const value = raw[key];

    if (typeof value === "string" && value.trim()) {
      return value.trim();
    }

    if (value !== undefined && value !== null && value !== "") {
      skipped.push(`${key}: expected a model specification`);
    }

    return null;
  };
  const confidence = raw.classifierMinConfidence;
  const validConfidence =
    typeof confidence === "number" &&
    Number.isFinite(confidence) &&
    confidence >= 0 &&
    confidence <= 100;

  if (confidence !== undefined && confidence !== null && !validConfidence) {
    skipped.push(`classifierMinConfidence: ${JSON.stringify(confidence)}`);
  }

  const mode = raw.classifierFallbackMode;

  if (mode !== undefined && mode !== "shadow" && mode !== "enforce") {
    skipped.push(`classifierFallbackMode: ${JSON.stringify(mode)}`);
  }

  const nested = raw.codemodeNestedCalls;

  if (nested !== undefined && nested !== "gate" && nested !== "rules-only") {
    skipped.push(`codemodeNestedCalls: ${JSON.stringify(nested)}`);
  }

  let enabled = boolean("enabled");

  try {
    if (fs.existsSync(getAgentSettingsPath())) {
      verdictSection(fs.readFileSync(getAgentSettingsPath(), "utf8"));
    }
  } catch {
    skipped.push("settings.json: invalid JSON; default rules remain active");
    enabled = true;
  }

  return {
    enabled,
    skipped,
    rules: {
      debug: boolean("debug"),
      allow: compile("allow"),
      deny: compile("deny"),
      denyPaths: strings("denyPaths"),
      ignoreTools: strings("ignoreTools"),
      builtinDenyFloor: boolean("builtinDenyFloor"),
      classifierModel: model("classifierModel"),
      audit: boolean("audit"),
      auditRedactSecrets: boolean("auditRedactSecrets"),
      notifyAllows: boolean("notifyAllows"),
      classifierMinConfidence: validConfidence ? confidence : null,
      classifierFallbackModel: model("classifierFallbackModel"),
      classifierFallbackMode:
        mode === undefined || mode === "enforce" ? "enforce" : "shadow",
      codemodeNestedCalls: nested === "rules-only" ? "rules-only" : "gate",
    },
  };
}

export function saveEnabled(enabled: boolean): void {
  const file = getAgentSettingsPath();

  if (fs.existsSync(file)) {
    verdictSection(fs.readFileSync(file, "utf8"));
  }

  saveExtensionSettingsPatch<VerdictSettings>({
    extensionKey: EXTENSION_KEY,
    patch: { enabled },
  });
}

export function verdictSection(content: string): unknown {
  const settings: unknown = JSON.parse(content);

  if (!settings || typeof settings !== "object" || Array.isArray(settings)) {
    throw new Error("Settings must be an object");
  }

  const extensions = (settings as Record<string, unknown>).extensionSettings;

  if (extensions === undefined) {
    return undefined;
  }

  if (
    !extensions ||
    typeof extensions !== "object" ||
    Array.isArray(extensions)
  ) {
    throw new Error("extensionSettings must be an object");
  }

  return (extensions as Record<string, unknown>)[EXTENSION_KEY];
}

export function settingsPreserveVerdict(
  current: string,
  proposed: string,
): boolean {
  try {
    return isDeepStrictEqual(verdictSection(current), verdictSection(proposed));
  } catch {
    return false;
  }
}

// A tagged snapshot distinguishes an absent section from an unreadable settings file.
export function snapshotVerdictSection(file: string): Buffer {
  try {
    return Buffer.from(
      JSON.stringify({ value: verdictSection(fs.readFileSync(file, "utf8")) }),
    );
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return Buffer.from("{}");
    }

    return Buffer.from('{"invalid":true}');
  }
}

export function restoreVerdictSection(file: string, snapshot: Buffer): void {
  const saved = JSON.parse(snapshot.toString()) as {
    value?: unknown;
    invalid?: true;
  };

  if (saved.invalid) {
    throw new Error("Cannot restore an invalid settings baseline");
  }

  const settings = fs.existsSync(file)
    ? JSON.parse(fs.readFileSync(file, "utf8"))
    : {};

  if (!settings || typeof settings !== "object" || Array.isArray(settings)) {
    throw new Error("Settings must be an object");
  }

  const extensions = settings.extensionSettings ?? {};

  if (
    !extensions ||
    typeof extensions !== "object" ||
    Array.isArray(extensions)
  ) {
    throw new Error("extensionSettings must be an object");
  }

  if (saved.value === undefined) {
    delete extensions[EXTENSION_KEY];
  } else {
    extensions[EXTENSION_KEY] = saved.value;
  }

  settings.extensionSettings = extensions;
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(settings, null, 2) + "\n");
}
