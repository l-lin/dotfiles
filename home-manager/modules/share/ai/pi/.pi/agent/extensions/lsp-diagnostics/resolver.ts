import * as os from "node:os";
import * as path from "node:path";
import * as fs from "node:fs";
import type {
  LspCommandSource,
  LspDiagnosticsFileConfig,
  LspServerConfig,
  SavedConfig,
} from "./types.js";

// ─── URI helpers ──────────────────────────────────────────────────────────────

export function fileUriToPath(uri: string): string {
  return decodeURIComponent(uri.replace(/^file:\/\//, ""));
}

export function pathToFileUri(p: string): string {
  // Encode each segment so chars like '#' and '?' aren't misread as URI delimiters.
  const abs = p.startsWith("/") ? p : "/" + p;
  return "file://" + abs.split("/").map(encodeURIComponent).join("/");
}

/**
 * Resolve symlinks and normalize path to canonical form.
 * Falls back to original path if realpath fails (file doesn't exist yet).
 */
export function canonicalizePath(p: string): string {
  try {
    return fs.realpathSync(p);
  } catch {
    // File doesn't exist or not accessible — return as-is
    return p;
  }
}

/**
 * Convert a file path to a canonical URI (symlinks resolved).
 * Use this for consistent URI matching between client and server.
 */
export function pathToCanonicalUri(p: string): string {
  const canonical = canonicalizePath(p);
  return pathToFileUri(canonical);
}

/**
 * Convert a URI to a canonical URI (resolve symlinks if file exists).
 * Useful for normalizing incoming URIs from LSP servers.
 */
export function canonicalizeUri(uri: string): string {
  const p = fileUriToPath(uri);
  return pathToCanonicalUri(p);
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
  ".xsd": "xml",
  ".xsl": "xml",
  ".xslt": "xml",
  ".svg": "xml",
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

/** Default Mason.nvim binary location — overridden per-server by lsp-diagnostics.ts. */
const LSP_BIN_PATH = path.join(os.homedir(), ".local/share/nvim/mason/bin");

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
 * Finds all servers in the file config whose fileTypes includes the
 * extension of the given file. Returns an empty array if none match.
 */
function matchAllFileConfigs(
  filePath: string,
  fileConfig: LspDiagnosticsFileConfig | null,
): LspServerConfig[] {
  if (!fileConfig) return [];
  const ext = path.extname(filePath).toLowerCase();
  return Object.values(fileConfig.servers).filter((server) =>
    server.fileTypes.includes(ext),
  );
}

/**
 * Resolves LSP commands in priority order:
 *   1. Explicit lsp_command from the tool call → single result
 *   2. Per-language saved session override     → single result
 *   3. Global saved session fallback           → single result
 *   4. Bundled config (lsp-diagnostics.ts) → ALL matching servers
 *   5. [] — no LSP available for this file type
 */
export interface ResolvedLspCommand {
  command: string[];
  rootMarkers: string[];
  settings: Record<string, unknown> | undefined;
  capabilities: Record<string, unknown> | undefined;
  source: LspCommandSource;
}

export function resolveLspCommands(
  files: string[],
  explicitCommand: string[] | undefined,
  savedConfig: SavedConfig | null,
  fileConfig: LspDiagnosticsFileConfig | null = null,
): ResolvedLspCommand[] {
  if (explicitCommand && explicitCommand.length > 0) {
    return [
      {
        command: explicitCommand,
        rootMarkers: [],
        settings: undefined,
        capabilities: undefined,
        source: "explicit",
      },
    ];
  }

  const lang = resolveLanguage(files);

  if (lang && savedConfig?.perLanguage[lang]) {
    return [
      {
        command: savedConfig.perLanguage[lang]!,
        rootMarkers: [],
        settings: undefined,
        capabilities: undefined,
        source: "per-language",
      },
    ];
  }

  if (savedConfig?.lspCommand && savedConfig.lspCommand.length > 0) {
    return [
      {
        command: savedConfig.lspCommand,
        rootMarkers: [],
        settings: undefined,
        capabilities: undefined,
        source: "global",
      },
    ];
  }

  // File-based config: return ALL servers matching the file extension
  if (files.length > 0) {
    const matched = matchAllFileConfigs(files[0]!, fileConfig);
    return matched.map((serverConfig) => {
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
        capabilities: serverConfig.capabilities,
        source: "file-config" as LspCommandSource,
      };
    });
  }

  return [];
}
