/**
 * lsp-diagnostics pi extension
 *
 * Automatically runs LSP diagnostics after every write/edit tool call and
 * appends results to the tool result so the LLM can self-correct immediately.
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
  truncateHead,
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  isEditToolResult,
  isWriteToolResult,
} from "@mariozechner/pi-coding-agent";
import * as path from "node:path";
import type { SavedConfig } from "./types.js";
import { CONFIG_ENTRY_TYPE } from "./types.js";
import { loadConfig, saveEnabled } from "./config.js";
import { resolveLspCommand } from "./resolver.js";
import { formatDiagnostics } from "./format.js";
import { PersistentLspClient } from "./lsp-client.js";

const DIAGNOSTICS_TIMEOUT_IN_MS = 30_000;

export default function (pi: ExtensionAPI) {
  const config = loadConfig();

  let savedConfig: SavedConfig | null = null;
  // Persistent LSP clients keyed by command string — created lazily, shut down on session_end
  const lspClients = new Map<string, PersistentLspClient>();
  // ── /lsp toggle command ──────────────────────────────────────────────────
  pi.registerCommand("cmd:lsp", {
    description: "Toggle auto LSP diagnostics on/off for this session",
    handler: async (_args, ctx) => {
      config.enabled = !config.enabled;
      saveEnabled(config.enabled);
      ctx.ui.notify(
        `lsp-diagnostics ${config.enabled ? "enabled" : "disabled"}`,
        "info",
      );
    },
  });

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

  // ── Widget helpers ───────────────────────────────────────────────────────
  const WIDGET_KEY = "lsp-diagnostics";

  function setLspWidget(
    ctx: { ui: { setWidget: (key: string, widget: any) => void } },
    lspBin: string,
    running: boolean,
  ) {
    ctx.ui.setWidget(
      WIDGET_KEY,
      (
        _tui: unknown,
        theme: { fg: (color: string, text: string) => string },
      ) => {
        const label = running
          ? `⚡ LSP diagnostics running (${lspBin})…`
          : `● LSP connected (${lspBin})`;
        const color = running ? "warning" : "success";
        const line = theme.fg(color, label);
        return { render: () => [line], invalidate: () => {} };
      },
    );
  }

  // ── /lsp-kill command ────────────────────────────────────────────────────
  pi.registerCommand("cmd:lsp-kill", {
    description: "Manually shut down one or all active LSP server(s)",
    handler: async (_args, ctx) => {
      if (lspClients.size === 0) {
        ctx.ui.notify("No active LSP servers.", "info");
        return;
      }

      const ALL_LABEL = "󰅖 ALL";
      const options = [ALL_LABEL, ...lspClients.keys()].map((k) =>
        k === ALL_LABEL ? k : `󰅖 ${k}`,
      );
      const chosen = await ctx.ui.select(
        "Select an LSP server to kill:",
        options,
      );
      if (!chosen) return;

      if (chosen === ALL_LABEL) {
        const count = lspClients.size;
        const shutdowns = [...lspClients.values()].map((c) => c.shutdown());
        lspClients.clear();
        await Promise.allSettled(shutdowns);
        ctx.ui.setWidget(WIDGET_KEY, undefined);
        ctx.ui.notify(`Killed all ${count} LSP server(s).`, "info");
      } else {
        const key = chosen.slice(chosen.indexOf(" ") + 1);
        const client = lspClients.get(key);
        if (!client) {
          ctx.ui.notify(`LSP server "${key}" not found.`, "error");
          return;
        }
        await client.shutdown();
        lspClients.delete(key);
        if (lspClients.size === 0) ctx.ui.setWidget(WIDGET_KEY, undefined);
        ctx.ui.notify(`Killed LSP server "${key}".`, "info");
      }
    },
  });

  // ── Shut down all LSP clients when the session ends ─────────────────────
  pi.on("session_end", async (_event, ctx) => {
    const shutdowns = [...lspClients.values()].map((c) => c.shutdown());
    lspClients.clear();
    await Promise.allSettled(shutdowns);
    ctx.ui.setWidget(WIDGET_KEY, undefined);
  });

  // ── Auto-diagnose after write/edit ───────────────────────────────────────
  pi.on("tool_result", async (event, ctx) => {
    if (!config.enabled) return;
    if (!isWriteToolResult(event) && !isEditToolResult(event)) return;

    const filePath = event.input.path;
    if (!filePath) return;

    const resolved = resolveLspCommand([filePath], undefined, savedConfig);
    if (!resolved) return; // No LSP available for this file type — skip silently

    const commandKey = resolved.command.join(" ");
    const lspBin = resolved.command[0]!;

    let allDiagnostics: Map<string, any>;
    try {
      // Get or create a persistent client for this LSP command
      let client = lspClients.get(commandKey);
      if (!client) {
        client = await PersistentLspClient.create(
          resolved.command,
          ctx.cwd,
          (msg, severity = "info") => ctx.ui.notify(msg, severity),
        );
        lspClients.set(commandKey, client);
      }
      setLspWidget(ctx, lspBin, true);
      allDiagnostics = await client.getDiagnostics(
        [filePath],
        ctx.cwd,
        DIAGNOSTICS_TIMEOUT_IN_MS,
        AbortSignal.timeout(DIAGNOSTICS_TIMEOUT_IN_MS),
      );
    } catch (err: any) {
      // Client may be in a broken state — remove it so next call spawns fresh
      lspClients.delete(commandKey);
      // If no clients left, clear the widget entirely
      if (lspClients.size === 0) ctx.ui.setWidget(WIDGET_KEY, undefined);
      // Don't break the tool result on LSP failure — just skip
      ctx.ui.notify(
        `lsp-diagnostics: ${err?.message ?? String(err)}`,
        "warning",
      );
      return;
    } finally {
      // Revert to idle if client is still alive, otherwise widget was already cleared
      if (lspClients.has(commandKey)) setLspWidget(ctx, lspBin, false);
    }

    const { text, errorCount, warningCount } = formatDiagnostics(
      allDiagnostics,
      ctx.cwd,
    );

    // Skip appending when there's nothing to report — no noise for clean files
    if (errorCount === 0 && warningCount === 0) return;

    const relPath = path.relative(ctx.cwd, path.resolve(ctx.cwd, filePath));
    const summary = `${errorCount} error(s), ${warningCount} warning(s)`;
    const header =
      `\n\n--- LSP Diagnostics (${resolved.command[0]}) — ${summary} ---\n` +
      `File: ${relPath}\n` +
      "─".repeat(60) +
      "\n";

    const full = header + (text.length > 0 ? text : "(no diagnostics)");
    const truncation = truncateHead(full, {
      maxLines: DEFAULT_MAX_LINES,
      maxBytes: DEFAULT_MAX_BYTES,
    });

    let diagnosticBlock = truncation.content;
    if (truncation.truncated) {
      diagnosticBlock += `\n[Output truncated: ${truncation.outputLines}/${truncation.totalLines} lines shown]`;
    }

    // Append diagnostics to the existing tool result content, preserving all content items
    const content = [...(event.content ?? [])];
    if (content.length === 0) {
      content.push({ type: "text", text: diagnosticBlock });
    } else {
      const last = content[content.length - 1];
      content[content.length - 1] = {
        ...last,
        text: ((last as any).text ?? "") + diagnosticBlock,
      };
    }
    return { content };
  });
}
