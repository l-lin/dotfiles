/**
 * lsp-diagnostics pi extension
 *
 * Automatically runs LSP diagnostics after every write/edit tool call and
 * appends results to the tool result so the LLM can self-correct immediately.
 * Updates the LSP widget with a summary of diagnostics.
 */
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
  isEditToolResult,
  isWriteToolResult,
} from "@mariozechner/pi-coding-agent";
import * as path from "node:path";
import type { LspDiagnostic, SavedConfig } from "./types.js";
import {
  getOrCreateClient,
  handleLspError,
  buildDiagnosticBlock,
} from "./tool-result-helpers.js";
import { CONFIG_ENTRY_TYPE } from "./types.js";
import { loadConfig, loadFileConfig } from "./config.js";
import { resolveLspCommands, resolveRootDir } from "./resolver.js";
import type { LspClientEntry } from "./lsp-details.js";
import { setLspWidget, syncLspServers, clearWidget } from "./widget.js";
import {
  handleCheck,
  handleToggle,
  handleKill,
  handleDetails,
} from "./commands/index.js";

// Short timeout - LSP may not send diagnostics for clean files
const DIAGNOSTICS_TIMEOUT_IN_MS = 3_000;

export default function (pi: ExtensionAPI) {
  const config = loadConfig();
  // Loaded once at startup — reflects ~/.pi/agent/lsp-diagnostics.json
  const fileConfig = loadFileConfig();

  let savedConfig: SavedConfig | null = null;
  // Persistent LSP clients keyed by command string — created lazily, shut down on session end
  const lspClients = new Map<string, LspClientEntry>();

  // ── LSP Commands ─────────────────────────────────────────────────────────
  pi.registerCommand("cmd:lsp-check", {
    description: "Check LSP diagnostics for a file or directory",
    handler: async (args, ctx) => {
      const filePath = args.split(" ")[0] || undefined;
      await handleCheck(lspClients, ctx, savedConfig, pi, filePath);
    },
  });

  pi.registerCommand("cmd:lsp-toggle", {
    description: "Toggle LSP extension on/off",
    handler: async (_args, ctx) => {
      await handleToggle(config, ctx);
    },
  });

  pi.registerCommand("cmd:lsp-kill", {
    description: "Kill active LSP server(s)",
    handler: async (_args, ctx) => {
      await handleKill(lspClients, ctx);
    },
  });

  pi.registerCommand("cmd:lsp-details", {
    description: "Show LSP server details",
    handler: async (_args, ctx) => {
      await handleDetails(lspClients, ctx);
    },
  });

  // ── Restore config from session ──────────────────────────────────────────
  pi.on("session_start", async (_event, ctx) => {
    savedConfig = null;
    const saved = [...ctx.sessionManager.getEntries()].findLast(
      (
        e,
      ): e is import("@mariozechner/pi-coding-agent").SessionEntry & {
        type: "custom";
        data?: unknown;
      } => e.type === "custom" && (e as any).customType === CONFIG_ENTRY_TYPE,
    );
    if (saved && saved.data) savedConfig = saved.data as SavedConfig;

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

  // ── Shut down all LSP clients when the session ends ─────────────────────
  pi.on("session_shutdown", async (_event, ctx) => {
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

    const filePath = event.input.path as string | undefined;
    if (!filePath) return;

    const resolvedList = resolveLspCommands(
      [filePath],
      undefined,
      savedConfig,
      fileConfig,
    );
    if (resolvedList.length === 0) return;

    // Fan out to all matching LSP servers in parallel
    const mergedDiagnostics = new Map<string, LspDiagnostic[]>();
    // Track diagnostics per server for widget display
    const perServerDiagnostics = new Map<
      string,
      Map<string, LspDiagnostic[]>
    >();
    // Track timing per server
    const perServerTiming = new Map<
      string,
      {
        initDurationMs: number;
        lastCheckDurationMs: number;
        receivedResponse: boolean;
      }
    >();
    // Pre-compute ordered bins from resolvedList for deterministic labeling.
    // successSet tracks which servers actually produced results.
    const orderedBins = resolvedList.map((r) => path.basename(r.command[0]!));
    const successSet = new Set<string>();

    // Remove any widget entries from previous files that aren't active this run
    syncLspServers(ctx, orderedBins);

    await Promise.all(
      resolvedList.map(async (resolved) => {
        const rootDir =
          resolved.rootMarkers.length > 0
            ? resolveRootDir(filePath, resolved.rootMarkers, ctx.cwd)
            : ctx.cwd;
        const commandKey = `${resolved.command.join(" ")}::${rootDir}`;
        const lspBin = path.basename(resolved.command[0]!);

        let serverDiagnostics: Map<string, LspDiagnostic[]>;
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
          const result = await entry.client.getDiagnostics(
            [filePath],
            ctx.cwd,
            DIAGNOSTICS_TIMEOUT_IN_MS,
            AbortSignal.timeout(DIAGNOSTICS_TIMEOUT_IN_MS),
          );
          serverDiagnostics = result.diagnostics;

          // Store timing info
          perServerTiming.set(lspBin, {
            initDurationMs: entry.client.initDurationMs,
            lastCheckDurationMs: result.durationMs,
            receivedResponse: result.receivedResponse,
          });

          // Log timing info if timed out
          if (!result.receivedResponse) {
            ctx.ui.notify(
              `lsp-diagnostics: ${lspBin} timed out after ${result.durationMs}ms (${result.urisResolved}/${result.urisRequested} files)`,
              "warning",
            );
          }
        } catch (err) {
          handleLspError(err, commandKey, ctx, lspClients);
          return;
        }

        successSet.add(lspBin);
        // Store per-server diagnostics for widget display
        perServerDiagnostics.set(lspBin, serverDiagnostics);
        // Merge: append diagnostics per URI across all servers
        for (const [uri, diags] of serverDiagnostics) {
          const existing = mergedDiagnostics.get(uri) ?? [];
          mergedDiagnostics.set(uri, [...existing, ...diags]);
        }
      }),
    );

    // All servers failed — individual errors already surfaced via handleLspError
    if (successSet.size === 0) return;

    // Update each server's widget
    for (const bin of successSet) {
      const serverDiags = perServerDiagnostics.get(bin)!;
      const timing = perServerTiming.get(bin);
      setLspWidget(ctx, bin, "idle", serverDiags, timing);
    }

    // Build label in resolvedList order (deterministic), only for successful servers
    const lspBinLabel = orderedBins
      .filter((bin) => successSet.has(bin))
      .join("+");
    const details = buildDiagnosticBlock(
      mergedDiagnostics,
      filePath,
      lspBinLabel,
      ctx.cwd,
    );
    // Append diagnostics to the tool result content so the LLM sees them.
    if (details !== null) {
      return {
        content: [
          ...event.content,
          { type: "text" as const, text: `\n${details}` },
        ],
      };
    }
  });
}
