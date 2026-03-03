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

/**
 * Per-server definition in ~/.pi/agent/lsp-diagnostics.json.
 * Supports rich configuration including file type routing and project root detection.
 */
export interface LspServerConfig {
  /** Binary name or absolute path */
  command: string;
  /** CLI arguments passed to the binary (e.g. ["--stdio"]) */
  args?: string[];
  /** File extensions this server handles (e.g. [".ts", ".tsx"]) */
  fileTypes: string[];
  /**
   * Filenames/dirs used to detect the project root.
   * The extension walks up from the edited file and uses the first dir
   * containing any of these markers as the LSP rootUri.
   */
  rootMarkers?: string[];
  /**
   * Arbitrary settings sent to the LSP via workspace/didChangeConfiguration
   * immediately after initialization. Shape is server-specific.
   */
  settings?: Record<string, unknown>;
  /**
   * Custom LSP client capabilities advertised during initialization.
   * Merged into the default capabilities when provided.
   */
  capabilities?: Record<string, unknown>;
}

/** Shape of ~/.pi/agent/lsp-diagnostics.json */
export interface LspDiagnosticsFileConfig {
  servers: Record<string, LspServerConfig>;
}

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
  | "file-config"
  | "default";

// ─── Constants ────────────────────────────────────────────────────────────────

export const SEVERITY_LABELS: Record<number, string> = {
  1: "error",
  2: "warning",
  3: "info",
  4: "hint",
};

export const CONFIG_ENTRY_TYPE = "lsp-diagnostics-config";
