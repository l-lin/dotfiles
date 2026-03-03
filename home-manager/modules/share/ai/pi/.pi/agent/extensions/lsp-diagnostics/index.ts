/**
 * lsp-diagnostics pi extension
 *
 * Automatically runs LSP diagnostics after every write/edit tool call and
 * appends results to the tool result so the LLM can self-correct immediately.
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
  isEditToolResult,
  isWriteToolResult,
} from "@mariozechner/pi-coding-agent";
import type { TUI } from "@mariozechner/pi-tui";
import * as path from "node:path";
import type { LspDiagnostic, SavedConfig } from "./types.js";
import {
  getOrCreateClient,
  handleLspError,
  buildDiagnosticBlock,
  appendToContent,
} from "./tool-result-helpers.js";
import { CONFIG_ENTRY_TYPE } from "./types.js";
import { loadConfig, loadFileConfig, saveEnabled } from "./config.js";
import { resolveLspCommand, resolveRootDir } from "./resolver.js";
import { LspDebugComponent, type LspClientEntry } from "./lsp-debug.js";
import { setLspWidget, clearWidget, LSP_ICON } from "./widget.js";

const DIAGNOSTICS_TIMEOUT_IN_MS = 30_000;

export default function (pi: ExtensionAPI) {
  const config = loadConfig();
  // Loaded once at startup — reflects ~/.pi/agent/lsp-diagnostics.json
  const fileConfig = loadFileConfig();

  let savedConfig: SavedConfig | null = null;
  // Persistent LSP clients keyed by command string — created lazily, shut down on session end
  const lspClients = new Map<string, LspClientEntry>();

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
    const saved = [...ctx.sessionManager.getEntries()].findLast(
      (e) => e.type === "custom" && e.customType === CONFIG_ENTRY_TYPE,
    );
    if (saved) savedConfig = saved.data as SavedConfig;

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

  // ── /lsp-kill command ────────────────────────────────────────────────────
  pi.registerCommand("cmd:lsp-kill", {
    description: "Manually shut down one or all active LSP server(s)",
    handler: async (_args, ctx) => {
      if (lspClients.size === 0) {
        ctx.ui.notify("No active LSP servers.", "info");
        return;
      }

      const ALL_LABEL = `${LSP_ICON} ALL`;
      // Map display label → original commandKey so icon-prefix stripping can't silently mismatch
      const labelToKey = new Map<string, string>();
      for (const k of lspClients.keys()) {
        labelToKey.set(`${LSP_ICON} ${k}`, k);
      }
      const options = [ALL_LABEL, ...labelToKey.keys()];
      const chosen = await ctx.ui.select(
        "Select an LSP server to kill:",
        options,
      );
      if (!chosen) return;

      if (chosen === ALL_LABEL) {
        const count = lspClients.size;
        const shutdowns = [...lspClients.values()].map(({ client }) =>
          client.shutdown(),
        );
        lspClients.clear();
        await Promise.allSettled(shutdowns);
        clearWidget(ctx);
        ctx.ui.notify(`Killed all ${count} LSP server(s).`, "info");
      } else {
        const key = labelToKey.get(chosen)!;
        const entry = lspClients.get(key);
        if (!entry) {
          ctx.ui.notify(`LSP server "${key}" not found.`, "error");
          return;
        }
        await entry.client.shutdown();
        lspClients.delete(key);
        if (lspClients.size === 0) {
          clearWidget(ctx);
        }
        ctx.ui.notify(`Killed LSP server "${key}".`, "info");
      }
    },
  });

  // ── /lsp-debug command ──────────────────────────────────────────────────
  pi.registerCommand("cmd:lsp-debug", {
    description:
      "Show detailed debug info for all active LSP server(s) in an interactive TUI",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;

      await ctx.ui.custom(
        (tui: TUI, theme: unknown, _kb: unknown, done: () => void) => {
          return new LspDebugComponent(lspClients, tui, theme, done);
        },
      );
    },
  });

  // ── Shut down all LSP clients when the session ends ─────────────────────
  pi.on("session_end", async (_event, ctx) => {
    const shutdowns = [...lspClients.values()].map(({ client }) =>
      client.shutdown(),
    );
    lspClients.clear();
    await Promise.allSettled(shutdowns);
    clearWidget(ctx);
  });

  // ── Auto-diagnose after write/edit ───────────────────────────────────────
  pi.on("tool_result", async (event, ctx) => {
    if (!config.enabled) return;
    if (!isWriteToolResult(event) && !isEditToolResult(event)) return;

    const filePath = event.input.path;
    if (!filePath) return;

    const resolved = resolveLspCommand(
      [filePath],
      undefined,
      savedConfig,
      fileConfig,
    );
    if (!resolved) return;

    const rootDir =
      resolved.rootMarkers.length > 0
        ? resolveRootDir(filePath, resolved.rootMarkers, ctx.cwd)
        : ctx.cwd;
    const commandKey = `${resolved.command.join(" ")}::${rootDir}`;
    const lspBin = path.basename(resolved.command[0]!);

    let diagnostics: Map<string, LspDiagnostic[]>;
    try {
      const entry = await getOrCreateClient(
        resolved,
        rootDir,
        commandKey,
        lspBin,
        ctx,
        lspClients,
      );
      setLspWidget(ctx, lspBin, "collecting");
      diagnostics = await entry.client.getDiagnostics(
        [filePath],
        ctx.cwd,
        DIAGNOSTICS_TIMEOUT_IN_MS,
        AbortSignal.timeout(DIAGNOSTICS_TIMEOUT_IN_MS),
      );
    } catch (err) {
      handleLspError(err, commandKey, ctx, lspClients);
      return;
    } finally {
      if (lspClients.has(commandKey)) setLspWidget(ctx, lspBin, "idle");
    }

    const block = buildDiagnosticBlock(diagnostics, filePath, lspBin, ctx.cwd);
    if (!block) return;

    return { content: appendToContent(event.content, block) };
  });
}
