/** Reads ~/.pi/agent/settings.json (lspDiagnostics property) to provide configurable defaults. */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

export interface LspDiagnosticsConfig {
  /** Whether the lsp_get_diagnostics tool is registered. Default: true. */
  enabled: boolean;
}

const DEFAULTS: LspDiagnosticsConfig = {
  enabled: true,
};

const CONFIG_PATH = path.join(os.homedir(), ".pi", "agent", "settings.json");

/** Loads config from disk once at startup. */
export function loadConfig(): LspDiagnosticsConfig {
  try {
    const raw = fs.readFileSync(CONFIG_PATH, "utf-8");
    const settings = JSON.parse(raw) as {
      lspDiagnostics?: Partial<LspDiagnosticsConfig>;
    };
    const parsed = settings.lspDiagnostics ?? {};
    return {
      enabled:
        typeof parsed.enabled === "boolean" ? parsed.enabled : DEFAULTS.enabled,
    };
  } catch {
    // File missing or malformed — fall back to defaults silently
    return { ...DEFAULTS };
  }
}
