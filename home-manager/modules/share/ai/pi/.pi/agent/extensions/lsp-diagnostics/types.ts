// ─── LSP protocol types ───────────────────────────────────────────────────────

export interface LspDiagnostic {
  range: {
    start: { line: number; character: number };
    end: { line: number; character: number };
  };
  severity?: 1 | 2 | 3 | 4; // Error=1 Warning=2 Info=3 Hint=4
  code?: string | number;
  source?: string;
  message: string;
}

export interface PublishDiagnosticsParams {
  uri: string;
  diagnostics: LspDiagnostic[];
}

// ─── Config types ─────────────────────────────────────────────────────────────

export interface SavedConfig {
  /** Global fallback command (legacy, set by /lsp-config without a language). */
  lspCommand?: string[];
  /** Per-language overrides, keyed by languageId. Takes priority over lspCommand. */
  perLanguage: Record<string, string[]>;
}

export type LspCommandSource =
  | "explicit"
  | "per-language"
  | "global"
  | "default";

// ─── Constants ────────────────────────────────────────────────────────────────

export const SEVERITY_LABELS: Record<number, string> = {
  1: "error",
  2: "warning",
  3: "info",
  4: "hint",
};

export const CONFIG_ENTRY_TYPE = "lsp-diagnostics-config";
