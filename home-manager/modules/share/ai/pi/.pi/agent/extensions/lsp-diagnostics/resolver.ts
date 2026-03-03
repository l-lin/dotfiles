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
 * Walks up the directory tree from `filePath`, returning the first ancestor
 * directory that contains any of the given `rootMarkers`. Falls back to `cwd`.
 */
export function resolveRootDir(
  filePath: string,
  rootMarkers: string[],
  cwd: string,
): string {
  const abs = path.resolve(cwd, filePath);
  let dir = path.dirname(abs);
  const fsRoot = path.parse(dir).root;

  while (true) {
    for (const marker of rootMarkers) {
      if (fs.existsSync(path.join(dir, marker))) return dir;
    }
    if (dir === fsRoot) break;
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }

  return cwd;
}

/**
 * Finds the first server in the file config whose fileTypes includes the
 * extension of the given file. Returns null if none match.
 */
function matchFileConfig(
  filePath: string,
  fileConfig: {
    servers: Record<string, import("./types.js").LspServerConfig>;
  } | null,
): import("./types.js").LspServerConfig | null {
  if (!fileConfig) return null;
  const ext = path.extname(filePath).toLowerCase();
  for (const server of Object.values(fileConfig.servers)) {
    if (server.fileTypes.includes(ext)) return server;
  }
  return null;
}

/**
 * Resolves the LSP command in priority order:
 *   1. Explicit lsp_command from the tool call
 *   2. Per-language saved session override
 *   3. Global saved session fallback
 *   4. File-based config (~/.pi/agent/lsp-diagnostics.json), matched by fileTypes
 *   5. Built-in default for the detected language
 *   6. null — no LSP available for this file type
 */
export function resolveLspCommand(
  files: string[],
  explicitCommand: string[] | undefined,
  savedConfig: SavedConfig | null,
  fileConfig: {
    servers: Record<string, import("./types.js").LspServerConfig>;
  } | null = null,
): {
  command: string[];
  rootMarkers: string[];
  settings: Record<string, unknown> | undefined;
  source: LspCommandSource;
} | null {
  if (explicitCommand && explicitCommand.length > 0) {
    return { command: explicitCommand, rootMarkers: [], settings: undefined, source: "explicit" };
  }

  const lang = resolveLanguage(files);

  if (lang && savedConfig?.perLanguage[lang]) {
    return {
      command: savedConfig.perLanguage[lang]!,
      rootMarkers: [],
      settings: undefined,
      source: "per-language",
    };
  }

  if (savedConfig?.lspCommand && savedConfig.lspCommand.length > 0) {
    return {
      command: savedConfig.lspCommand,
      rootMarkers: [],
      settings: undefined,
      source: "global",
    };
  }

  // File-based config: match by file extension
  if (files.length > 0) {
    const serverConfig = matchFileConfig(files[0]!, fileConfig);
    if (serverConfig) {
      const bin = serverConfig.command;
      const args = serverConfig.args ?? [];
      const resolvedBin = `${LSP_BIN_PATH}/${bin}`;
      const command = fs.existsSync(resolvedBin)
        ? [resolvedBin, ...args]
        : [bin, ...args];
      return {
        command,
        rootMarkers: serverConfig.rootMarkers ?? [],
        settings: serverConfig.settings,
        source: "file-config",
      };
    }
  }

  // Built-in hardcoded defaults (legacy fallback keyed by languageId)
  if (lang && LANGUAGE_LSP_DEFAULTS[lang]) {
    const [bin, ...rest] = LANGUAGE_LSP_DEFAULTS[lang]!;
    const resolvedBin = `${LSP_BIN_PATH}/${bin}`;
    const command = fs.existsSync(resolvedBin)
      ? [resolvedBin, ...rest]
      : [bin!, ...rest];
    return { command, rootMarkers: [], settings: undefined, source: "default" };
  }

  return null;
}
