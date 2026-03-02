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
import * as path from "node:path";
import * as fs from "node:fs";
import { execSync } from "node:child_process";
import type { SavedConfig } from "./types.js";
import { CONFIG_ENTRY_TYPE } from "./types.js";
import { resolveLspCommand, resolveLanguage } from "./resolver.js";
import { formatDiagnostics } from "./format.js";

const EXTENSION_DIR = new URL(".", import.meta.url).pathname;

function ensureDependencies(notify: (msg: string) => void): void {
  const marker = path.join(EXTENSION_DIR, "node_modules", "vscode-jsonrpc");
  if (!fs.existsSync(marker)) {
    notify("lsp-diagnostics: installing dependencies...");
    execSync("npm install --silent", { cwd: EXTENSION_DIR, stdio: "ignore" });
  }
}

export default function (pi: ExtensionAPI) {
  let savedConfig: SavedConfig | null = null;

  // ── Restore config from session ──────────────────────────────────────────
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

  // ── lsp_get_diagnostics tool ─────────────────────────────────────────────
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

      ensureDependencies((msg) => ctx.ui.notify(msg, "info"));
      const { collectDiagnostics } = await import("./lsp-client.js");

      let allDiagnostics: Map<string, any>;
      try {
        allDiagnostics = await collectDiagnostics(
          lspCommand,
          params.files,
          ctx.cwd,
          params.timeout_ms ?? 10_000,
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
        ctx.cwd,
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
      const nbFiles = args.files?.length ?? 0;
      let filePart = `${nbFiles} file(s)`;
      if (nbFiles === 1) {
        filePart = path.basename(args.files[0]);
      }
      return new Text(
        theme.fg("toolTitle", theme.bold("lsp_get_diagnostics ")) +
          theme.fg("muted", filePart),
        0,
        0,
      );
    },

    renderResult(result, { expanded }, theme) {
      const { errorCount, warningCount, lspCommand, lspSource, files } =
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

      if (!expanded) {
        return new Text(
          errors + theme.fg("muted", ", ") + warnings,
          0,
          0,
        );
      }

      const fileList =
        files?.length > 0
          ? "\n" +
            files
              .map((f: string) => `  ${theme.fg("dim", `• ${path.basename(f)}`)}`)
              .join("\n")
          : "";

      return new Text(
        theme.fg("muted", `${cmd}`) +
          sourceLabel +
          theme.fg("muted", " — ") +
          errors +
          theme.fg("muted", ", ") +
          warnings +
          fileList,
        0,
        0,
      );
    },
  });
}
