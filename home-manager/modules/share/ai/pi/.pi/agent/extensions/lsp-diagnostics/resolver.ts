import * as os from "node:os";
import * as path from "node:path";
import * as fs from "node:fs";
import type { LspCommandSource, SavedConfig } from "./types.js";

// ─── URI helpers ──────────────────────────────────────────────────────────────

export function fileUriToPath(uri: string): string {
  return decodeURIComponent(uri.replace(/^file:\/\//, ""));
}

export function pathToFileUri(p: string): string {
  // Encode each segment so chars like '#' and '?' aren't misread as URI delimiters.
  const abs = p.startsWith("/") ? p : "/" + p;
  return "file://" + abs.split("/").map(encodeURIComponent).join("/");
}

// ─── Language detection ───────────────────────────────────────────────────────

const EXT_TO_LANGUAGE_ID: Record<string, string> = {
  ".ts": "typescript",
  ".tsx": "typescriptreact",
  ".js": "javascript",
  ".jsx": "javascriptreact",
  ".java": "java",
  ".rb": "ruby",
  ".lua": "lua",
  ".nix": "nix",
  ".yaml": "yaml",
  ".yml": "yaml",
  ".xml": "xml",
};

export function guessLanguageId(filePath: string): string {
  const ext = path.extname(filePath).toLowerCase();
  return EXT_TO_LANGUAGE_ID[ext] ?? "plaintext";
}

/**
 * Returns the shared languageId for all files, or null for mixed/unknown types.
 * Mixed languages can't be safely auto-routed to a single LSP server.
 */
export function resolveLanguage(filePaths: string[]): string | null {
  if (filePaths.length === 0) return null;
  const languages = filePaths.map(guessLanguageId);
  const unique = new Set(languages);
  return unique.size === 1 ? languages[0]! : null;
}

// ─── LSP command resolution ───────────────────────────────────────────────────

/**
 * My LSP binaries are installed here by mason.nvim.
 */
const LSP_BIN_PATH = path.join(os.homedir(), ".local/share/nvim/mason/bin");

/**
 * Built-in defaults keyed by languageId.
 * The commands are fetched from `:LspInfo` in Neovim.
 */
const LANGUAGE_LSP_DEFAULTS: Record<string, string[]> = {
  typescript: ["vtsls", "--stdio"],
  typescriptreact: ["vtsls", "--stdio"],
  javascript: ["vtsls", "--stdio"],
  javascriptreact: ["vtsls", "--stdio"],
  java: ["jdtls"],
  nix: ["nil"],
  lua: ["lua-language-server"],
  ruby: ["rubocop", "--lsp"],
  yaml: ["yaml-language-server", "--stdio"],
  xml: ["xmlformat", "--stdio"],
};

/**
 * Resolves the LSP command in priority order:
 *   1. Explicit lsp_command from the tool call
 *   2. Per-language saved override
 *   3. Global saved fallback
 *   4. Built-in default for the detected language
 *   5. null — caller should surface an error
 */
export function resolveLspCommand(
  files: string[],
  explicitCommand: string[] | undefined,
  savedConfig: SavedConfig | null,
): { command: string[]; source: LspCommandSource } | null {
  if (explicitCommand && explicitCommand.length > 0) {
    return { command: explicitCommand, source: "explicit" };
  }

  const lang = resolveLanguage(files);

  if (lang && savedConfig?.perLanguage[lang]) {
    return { command: savedConfig.perLanguage[lang]!, source: "per-language" };
  }

  if (savedConfig?.lspCommand && savedConfig.lspCommand.length > 0) {
    return { command: savedConfig.lspCommand, source: "global" };
  }

  if (lang && LANGUAGE_LSP_DEFAULTS[lang]) {
    const [bin, ...rest] = LANGUAGE_LSP_DEFAULTS[lang]!;
    const resolvedBin = `${LSP_BIN_PATH}/${bin}`;
    const command = fs.existsSync(resolvedBin)
      ? [resolvedBin, ...rest]
      : [bin!, ...rest];
    return { command, source: "default" };
  }

  return null;
}
