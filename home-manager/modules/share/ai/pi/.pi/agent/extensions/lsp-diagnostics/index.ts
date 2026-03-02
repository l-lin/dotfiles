/**
 * lsp-diagnostics pi extension
 *
 * Spawns any LSP server via stdio JSON-RPC, opens requested files,
 * collects publishDiagnostics notifications, and returns them to the LLM.
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
  truncateHead,
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
} from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { Text } from "@mariozechner/pi-tui";
import { spawn } from "node:child_process";
import * as os from "node:os";
import * as path from "node:path";
import * as fs from "node:fs";
import {
  createMessageConnection,
  StreamMessageReader,
  StreamMessageWriter,
} from "vscode-jsonrpc/node.js";

// ─── Types ────────────────────────────────────────────────────────────────────

interface LspDiagnostic {
  range: {
    start: { line: number; character: number };
    end: { line: number; character: number };
  };
  severity?: 1 | 2 | 3 | 4; // Error=1 Warning=2 Info=3 Hint=4
  code?: string | number;
  source?: string;
  message: string;
}

interface PublishDiagnosticsParams {
  uri: string;
  diagnostics: LspDiagnostic[];
}

interface SavedConfig {
  /** Global fallback command (legacy, set by /lsp-config without a language). */
  lspCommand?: string[];
  /** Per-language overrides, keyed by languageId. Takes priority over lspCommand. */
  perLanguage: Record<string, string[]>;
}

const SEVERITY_LABELS: Record<number, string> = {
  1: "error",
  2: "warning",
  3: "info",
  4: "hint",
};

const CONFIG_ENTRY_TYPE = "lsp-diagnostics-config";

/**
 * Directory to search for LSP binaries before falling back to PATH.
 * Override with the LSP_BIN_PATH env var.
 */
const LSP_BIN_PATH = path.join(os.homedir(), ".local/share/nvim/mason/bin");

/**
 * Built-in LSP command defaults keyed by languageId (from guessLanguageId).
 * These are the canonical, well-known server commands — binary must be in PATH.
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

// ─── Helpers ─────────────────────────────────────────────────────────────────

function fileUriToPath(uri: string): string {
  return decodeURIComponent(uri.replace(/^file:\/\//, ""));
}

function pathToFileUri(p: string): string {
  // encodeURIComponent each path segment so chars like '#' and '?' don't
  // get misinterpreted as URI fragment/query delimiters.
  const abs = p.startsWith("/") ? p : "/" + p;
  return "file://" + abs.split("/").map(encodeURIComponent).join("/");
}

function guessLanguageId(filePath: string): string {
  const ext = path.extname(filePath).toLowerCase();
  const map: Record<string, string> = {
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
  return map[ext] ?? "plaintext";
}

/**
 * Resolves the LSP command to use, in priority order:
 *   1. Explicit lsp_command from the tool call
 *   2. Per-language saved override (savedConfig.perLanguage[lang])
 *   3. Global saved fallback (savedConfig.lspCommand)
 *   4. Built-in default for the detected language (LANGUAGE_LSP_DEFAULTS)
 *   5. null — caller should surface an actionable error
 */
function resolveLspCommand(
  files: string[],
  explicitCommand: string[] | undefined,
  savedConfig: SavedConfig | null,
): {
  command: string[];
  source: "explicit" | "per-language" | "global" | "default";
} | null {
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

/**
 * Returns the single shared languageId for all files, or null if they're mixed.
 * Mixed languages can't be safely auto-routed to a single LSP server.
 */
function resolveLanguage(filePaths: string[]): string | null {
  if (filePaths.length === 0) return null;
  const languages = filePaths.map(guessLanguageId);
  const unique = new Set(languages);
  return unique.size === 1 ? languages[0]! : null;
}

/**
 * Formats collected diagnostics as a human-readable string for the LLM.
 * Each line: `path/to/file.ts:line:col [severity] message`
 */
function formatDiagnostics(
  allDiagnostics: Map<string, LspDiagnostic[]>,
  cwd: string,
): { text: string; errorCount: number; warningCount: number } {
  let errorCount = 0;
  let warningCount = 0;
  const lines: string[] = [];

  for (const [uri, diagnostics] of allDiagnostics) {
    const absPath = fileUriToPath(uri);
    const relPath = path.relative(cwd, absPath);

    if (diagnostics.length === 0) {
      lines.push(`${relPath}: no diagnostics`);
      continue;
    }

    for (const d of diagnostics) {
      const line = d.range.start.line + 1;
      const col = d.range.start.character + 1;
      const severity = SEVERITY_LABELS[d.severity ?? 1] ?? "error";
      const source = d.source ? `(${d.source}) ` : "";
      const code = d.code != null ? `[${d.code}] ` : "";
      lines.push(
        `${relPath}:${line}:${col} [${severity}] ${source}${code}${d.message}`,
      );

      if ((d.severity ?? 1) === 1) errorCount++;
      else if (d.severity === 2) warningCount++;
    }
  }

  return { text: lines.join("\n"), errorCount, warningCount };
}

/**
 * Spawns an LSP server, runs the full initialize → diagnose → shutdown lifecycle,
 * and returns all collected diagnostics.
 */
async function collectDiagnostics(
  lspCommand: string[],
  filePaths: string[],
  cwd: string,
  timeoutMs: number,
  signal?: AbortSignal,
  onError?: (msg: string, severity?: "info" | "warning" | "error") => void,
): Promise<Map<string, LspDiagnostic[]>> {
  const [cmd, ...args] = lspCommand;
  const proc = spawn(cmd, args, { cwd, stdio: ["pipe", "pipe", "pipe"] });

  // Monkey-patch proc.stdin.write so that writes to a destroyed stream silently
  // succeed (callback called with null) instead of rejecting. vscode-jsonrpc's
  // message writer queues writes via setImmediate; by the time they fire the
  // stream may already be destroyed after the LSP server exits post-shutdown.
  // Suppressing the 'error' event alone doesn't help because Node invokes the
  // write *callback* with the error, which rejects the Promise inside
  // WritableStreamWrapper — and that rejection is never caught upstream.
  if (proc.stdin) {
    const _origWrite = proc.stdin.write.bind(proc.stdin);
    (proc.stdin as any).write = function (
      chunk: any,
      encodingOrCb?: any,
      cb?: any,
    ): boolean {
      if (proc.stdin!.destroyed) {
        const callback = typeof encodingOrCb === "function" ? encodingOrCb : cb;
        if (typeof callback === "function") process.nextTick(callback, null);
        return false;
      }
      return _origWrite(chunk, encodingOrCb, cb);
    };
    proc.stdin.on("error", (err) =>
      onError?.(`lsp-diagnostics: stdin error — ${err.message}`, "info"),
    );
  }

  // Surface spawn errors (e.g. binary not found) as a rejected promise.
  // The .catch() suppresses unhandled-rejection if initialize() wins the race
  // first and the process later emits an error event on its own.
  const spawnError = new Promise<never>((_, reject) => {
    proc.on("error", (err) => reject(err));
  }).catch(() => {}) as Promise<never>;

  const connection = createMessageConnection(
    new StreamMessageReader(proc.stdout!),
    new StreamMessageWriter(proc.stdin!),
  );
  connection.listen();

  const allDiagnostics = new Map<string, LspDiagnostic[]>(
    filePaths.map((f) => [pathToFileUri(path.resolve(cwd, f)), []]),
  );
  const received = new Set<string>();

  // Collect publishDiagnostics notifications
  connection.onNotification(
    "textDocument/publishDiagnostics",
    (params: PublishDiagnosticsParams) => {
      if (allDiagnostics.has(params.uri)) {
        allDiagnostics.set(params.uri, params.diagnostics);
        received.add(params.uri);
      }
    },
  );

  try {
    // ── Initialize ────────────────────────────────────────────────────────
    await Promise.race([
      spawnError, // rejects immediately if binary not found
      connection.sendRequest("initialize", {
        processId: process.pid,
        rootUri: pathToFileUri(cwd),
        capabilities: {
          textDocument: {
            publishDiagnostics: { relatedInformation: false },
          },
          workspace: { workspaceFolders: true },
        },
        workspaceFolders: [
          { uri: pathToFileUri(cwd), name: path.basename(cwd) },
        ],
      }),
    ]);

    connection.sendNotification("initialized", {});

    // ── Open each file to trigger diagnostics ─────────────────────────────
    for (const filePath of filePaths) {
      const absPath = path.resolve(cwd, filePath);
      const uri = pathToFileUri(absPath);

      let text = "";
      try {
        text = fs.readFileSync(absPath, "utf8");
      } catch {
        // File unreadable — LSP will produce its own error
      }

      connection.sendNotification("textDocument/didOpen", {
        textDocument: {
          uri,
          languageId: guessLanguageId(absPath),
          version: 1,
          text,
        },
      });
    }

    // ── Wait for all diagnostics or timeout ───────────────────────────────
    const allUris = [...allDiagnostics.keys()];
    await new Promise<void>((resolve) => {
      const timer = setTimeout(resolve, timeoutMs);

      // Check periodically; also resolve early if all files covered
      const interval = setInterval(() => {
        if (allUris.every((u) => received.has(u))) {
          clearInterval(interval);
          clearTimeout(timer);
          resolve();
        }
      }, 200);

      // { once: true } auto-removes the listener after firing, preventing leaks
      signal?.addEventListener(
        "abort",
        () => {
          clearInterval(interval);
          clearTimeout(timer);
          resolve();
        },
        { once: true },
      );
    });

    // ── Shutdown gracefully ───────────────────────────────────────────────
    try {
      let shutdownTimer: ReturnType<typeof setTimeout> | undefined;
      await Promise.race([
        connection.sendRequest("shutdown", null),
        new Promise((_, reject) => {
          shutdownTimer = setTimeout(
            () => reject(new Error("shutdown timeout")),
            3000,
          );
        }),
      ]).finally(() => clearTimeout(shutdownTimer));
      if (!proc.stdin?.destroyed) {
        connection.sendNotification("exit", {});
      }
    } catch {
      // Ignore shutdown errors
    }
  } finally {
    connection.dispose();
    proc.kill();
  }

  return allDiagnostics;
}

// ─── Extension entry point ───────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  // In-memory config, restored from session on startup
  let savedConfig: SavedConfig | null = null;

  // ── Restore saved config from session ──────────────────────────────────
  pi.on("session_start", async (_event, ctx) => {
    savedConfig = null;
    for (const entry of ctx.sessionManager.getEntries()) {
      if (entry.type === "custom" && entry.customType === CONFIG_ENTRY_TYPE) {
        savedConfig = entry.data as SavedConfig;
      }
    }

    if (savedConfig) {
      const parts: string[] = [];
      if (savedConfig.lspCommand)
        parts.push(`global: ${savedConfig.lspCommand.join(" ")}`);
      for (const [lang, cmd] of Object.entries(savedConfig.perLanguage ?? {})) {
        parts.push(`${lang}: ${cmd.join(" ")}`);
      }
      if (parts.length > 0) {
        ctx.ui.notify(`lsp-diagnostics config — ${parts.join(" | ")}`, "info");
      }
    }
  });

  // ── lsp_get_diagnostics tool ────────────────────────────────────────────
  pi.registerTool({
    name: "lsp_get_diagnostics",
    label: "LSP Diagnostics",
    description: [
      "Spawn an LSP server and collect diagnostics (errors, warnings, hints) for the given files.",
      "The server is auto-detected from the file extension; pass lsp_command to override.",
      "Built-in defaults: .ts/.tsx/.js/.jsx → vtsls, .nix → nil, .lua → lua-language-server, .rb → rubocop --lsp, .yaml → yaml-language-server.",
    ].join("\n"),

    parameters: Type.Object({
      files: Type.Array(Type.String({ description: "File path to diagnose" }), {
        description: "List of files to get diagnostics for",
        minItems: 1,
      }),
      lsp_command: Type.Optional(
        Type.Array(Type.String(), {
          description:
            'LSP server command, e.g. ["typescript-language-server", "--stdio"]. Uses project default if omitted.',
        }),
      ),
      timeout_ms: Type.Optional(
        Type.Number({
          description:
            "Max milliseconds to wait for diagnostics (default: 10000)",
          minimum: 1000,
          maximum: 60000,
        }),
      ),
    }),

    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const resolved = resolveLspCommand(
        params.files,
        params.lsp_command,
        savedConfig,
      );

      if (!resolved) {
        const lang = resolveLanguage(params.files);
        const hint = lang
          ? `No built-in default for language "${lang}". Pass lsp_command explicitly.`
          : "Mixed or unknown file types — cannot auto-detect LSP server.\nPass lsp_command explicitly.";
        return {
          content: [{ type: "text", text: hint }],
          details: { errorCount: 0, warningCount: 0, lspCommand: null },
        };
      }

      const { command: lspCommand, source: lspSource } = resolved;

      const timeoutMs = params.timeout_ms ?? 10_000;
      const cwd = ctx.cwd;

      let allDiagnostics: Map<string, LspDiagnostic[]>;
      try {
        allDiagnostics = await collectDiagnostics(
          lspCommand,
          params.files,
          cwd,
          timeoutMs,
          signal,
          (msg, severity = "info") => ctx.ui.notify(msg, severity),
        );
      } catch (err: any) {
        return {
          content: [
            {
              type: "text",
              text: `LSP server error: ${err?.message ?? String(err)}`,
            },
          ],
          details: { errorCount: 0, warningCount: 0, lspCommand },
          isError: true,
        };
      }

      const { text, errorCount, warningCount } = formatDiagnostics(
        allDiagnostics,
        cwd,
      );

      const header =
        `LSP diagnostics (${lspCommand[0]}) — ` +
        `${errorCount} error(s), ${warningCount} warning(s)\n` +
        `Files: ${params.files.join(", ")}\n` +
        "─".repeat(60) +
        "\n";

      const full =
        text.length > 0 ? header + text : header + "(no diagnostics)";

      const truncation = truncateHead(full, {
        maxLines: DEFAULT_MAX_LINES,
        maxBytes: DEFAULT_MAX_BYTES,
      });

      let result = truncation.content;
      if (truncation.truncated) {
        result += `\n\n[Output truncated: ${truncation.outputLines}/${truncation.totalLines} lines shown]`;
      }

      return {
        content: [{ type: "text", text: result }],
        details: {
          errorCount,
          warningCount,
          lspCommand,
          lspSource,
          files: params.files,
        },
      };
    },

    renderCall(args, theme) {
      const autoResolved = resolveLspCommand(
        args.files ?? [],
        args.lsp_command,
        savedConfig,
      );
      const cmd = autoResolved ? autoResolved.command[0] : "LSP";
      const isAuto = !args.lsp_command && autoResolved?.source !== "explicit";
      const sourceLabel = isAuto
        ? theme.fg("dim", ` (${autoResolved?.source ?? "auto"})`)
        : "";
      const fileList =
        args.files?.length > 0
          ? args.files.map((f: string) => path.basename(f)).join(", ")
          : "…";
      return new Text(
        theme.fg("toolTitle", theme.bold("lsp_get_diagnostics ")) +
          theme.fg("muted", `${cmd}`) +
          sourceLabel +
          theme.fg("dim", ` [${fileList}]`),
        0,
        0,
      );
    },

    renderResult(result, _opts, theme) {
      const { errorCount, warningCount, lspCommand, lspSource } =
        result.details ?? {};

      if (result.isError) {
        return new Text(
          theme.fg("error", "✗ LSP error: ") +
            theme.fg("muted", result.content[0]?.text ?? ""),
          0,
          0,
        );
      }

      const cmd = lspCommand?.[0] ?? "LSP";
      const sourceLabel =
        lspSource && lspSource !== "explicit"
          ? theme.fg("dim", ` (${lspSource})`)
          : "";
      const errors =
        errorCount > 0
          ? theme.fg(
              "error",
              `${errorCount} error${errorCount !== 1 ? "s" : ""}`,
            )
          : theme.fg("success", "0 errors");
      const warnings =
        warningCount > 0
          ? theme.fg(
              "warning",
              `${warningCount} warning${warningCount !== 1 ? "s" : ""}`,
            )
          : theme.fg("muted", "0 warnings");

      return new Text(
        theme.fg("muted", `${cmd}`) +
          sourceLabel +
          theme.fg("muted", " — ") +
          errors +
          theme.fg("muted", ", ") +
          warnings,
        0,
        0,
      );
    },
  });
}
