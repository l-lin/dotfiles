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
import type { TUI } from "@mariozechner/pi-tui";
import * as path from "node:path";
import type { SavedConfig } from "./types.js";
import { CONFIG_ENTRY_TYPE } from "./types.js";
import { loadConfig, loadFileConfig, saveEnabled } from "./config.js";
import { resolveLspCommand, resolveRootDir } from "./resolver.js";
import { formatDiagnostics } from "./format.js";
import { PersistentLspClient } from "./lsp-client.js";
import { LspDebugComponent, type LspClientEntry } from "./lsp-debug.js";

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

  // ── Widget helpers ───────────────────────────────────────────────────────
  type WidgetCtx = {
    ui: { setWidget: (key: string, widget: unknown) => void };
  };

  const WIDGET_KEY = "lsp-diagnostics";
  const LSP_ICON = "";
  const LSP_STARTING_ICON = "";
  const LSP_BLINK_INTERVAL_MS = 500;

  const enum LspWidgetState {
    Starting = "starting",
    Collecting = "collecting",
    Idle = "idle",
  }

  // Blink timer — only active during the Collecting state
  let blinkTimer: ReturnType<typeof setInterval> | undefined;
  let blinkVisible = true;

  function stopBlink() {
    if (blinkTimer !== undefined) {
      clearInterval(blinkTimer);
      blinkTimer = undefined;
    }
    blinkVisible = true;
  }

  function renderLspWidget(
    ctx: WidgetCtx,
    lspBin: string,
    icon: string,
    iconVisible: boolean,
  ) {
    const renderedIcon = iconVisible ? icon : " ";
    ctx.ui.setWidget(
      WIDGET_KEY,
      (
        _tui: unknown,
        theme: {
          fg: (color: string, text: string) => string;
          bold: (text: string) => string;
        },
      ) => {
        const line =
          theme.fg("success", renderedIcon) + theme.bold(` ${lspBin}`);
        return { render: () => [line], invalidate: () => {} };
      },
    );
  }

  function setLspWidget(ctx: WidgetCtx, lspBin: string, state: LspWidgetState) {
    stopBlink();

    const icon =
      state === LspWidgetState.Starting ? LSP_STARTING_ICON : LSP_ICON;

    if (
      state === LspWidgetState.Starting ||
      state === LspWidgetState.Collecting
    ) {
      // Start blink loop
      blinkVisible = true;
      renderLspWidget(ctx, lspBin, icon, blinkVisible);
      blinkTimer = setInterval(() => {
        blinkVisible = !blinkVisible;
        renderLspWidget(ctx, lspBin, icon, blinkVisible);
      }, LSP_BLINK_INTERVAL_MS);
    } else {
      renderLspWidget(ctx, lspBin, icon, true);
    }
  }

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
        stopBlink();
        ctx.ui.setWidget(WIDGET_KEY, undefined);
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
          stopBlink();
          ctx.ui.setWidget(WIDGET_KEY, undefined);
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
      if (!ctx.hasUI) {
        if (lspClients.size === 0) {
          pi.sendMessage(
            {
              customType: "lsp-debug",
              content: "No active LSP servers.",
              display: true,
            },
            { triggerTurn: false },
          );
          return;
        }
        const lines: string[] = ["Active LSP Servers:"];
        for (const [_key, entry] of lspClients.entries()) {
          const info = entry.client.getDebugInfo();
          lines.push(`\n[${entry.bin}]`);
          lines.push(`  Command : ${entry.command.join(" ")}`);
          lines.push(`  Root    : ${entry.rootDir}`);
          lines.push(`  Started : ${entry.startedAt.toISOString()}`);
          lines.push(`  Files   : ${info.openedFiles.length}`);
          lines.push(
            `  Diags   : ${[...info.diagnosticsMap.values()].flat().length}`,
          );
          if (entry.settings) {
            lines.push(
              `  Settings: ${JSON.stringify(entry.settings, null, 2)}`,
            );
          }
        }
        pi.sendMessage(
          { customType: "lsp-debug", content: lines.join("\n"), display: true },
          { triggerTurn: false },
        );
        return;
      }

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
    stopBlink();
    ctx.ui.setWidget(WIDGET_KEY, undefined);
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
    if (!resolved) return; // No LSP available for this file type — skip silently

    // Resolve project root via rootMarkers — critical for multi-project workspaces
    const rootDir =
      resolved.rootMarkers.length > 0
        ? resolveRootDir(filePath, resolved.rootMarkers, ctx.cwd)
        : ctx.cwd;

    // Include rootDir in the cache key so each project gets its own LSP instance
    const commandKey = `${resolved.command.join(" ")}::${rootDir}`;
    const lspBin = path.basename(resolved.command[0]!);

    let allDiagnostics: Map<string, any>;
    try {
      // Get or create a persistent client for this LSP command + project root
      let entry = lspClients.get(commandKey);
      if (!entry) {
        setLspWidget(ctx, lspBin, LspWidgetState.Starting);
        const client = await PersistentLspClient.create(
          resolved.command,
          ctx.cwd,
          (msg, severity = "info") => ctx.ui.notify(msg, severity),
          rootDir,
          resolved.settings,
          resolved.capabilities,
        );
        entry = {
          client,
          bin: lspBin,
          command: resolved.command,
          rootDir,
          settings: resolved.settings,
          startedAt: new Date(),
        };
        lspClients.set(commandKey, entry);
      }
      setLspWidget(ctx, lspBin, LspWidgetState.Collecting);
      allDiagnostics = await entry.client.getDiagnostics(
        [filePath],
        ctx.cwd,
        DIAGNOSTICS_TIMEOUT_IN_MS,
        AbortSignal.timeout(DIAGNOSTICS_TIMEOUT_IN_MS),
      );
    } catch (err: any) {
      // Client may be in a broken state — remove it so next call spawns fresh
      lspClients.delete(commandKey);
      // Stop any active blink — the finally block won't do it since the key is gone
      if (lspClients.size === 0) {
        stopBlink();
        ctx.ui.setWidget(WIDGET_KEY, undefined);
      } else {
        // Other clients still alive — pick any surviving one to show in the widget
        const [survivingEntry] = lspClients.values();
        setLspWidget(ctx, survivingEntry!.bin, LspWidgetState.Idle);
      }
      // Don't break the tool result on LSP failure — just skip
      ctx.ui.notify(
        `lsp-diagnostics: ${err?.message ?? String(err)}`,
        "warning",
      );
      return;
    } finally {
      // Revert to idle if client is still alive; catch already handled the failure case
      if (lspClients.has(commandKey))
        setLspWidget(ctx, lspBin, LspWidgetState.Idle);
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
      `\n\n--- LSP Diagnostics (${lspBin}) — ${summary} ---\n` +
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
