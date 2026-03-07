/**
 * LSP command handlers
 * Consolidates all LSP commands into a single cmd:lsp with selection menu
 */
import type {
  ExtensionContext,
  ExtensionAPI,
} from "@mariozechner/pi-coding-agent";
import type { TUI } from "@mariozechner/pi-tui";
import * as path from "node:path";
import * as fs from "node:fs";
import type { LspClientEntry } from "./lsp-details.js";
import { LspDetailsComponent } from "./lsp-details.js";
import { clearWidget, LSP_ICON, setLspWidget } from "./widget.js";
import type { LspDiagnosticsConfig } from "./config.js";
import { saveEnabled, loadFileConfig } from "./config.js";
import { resolveLspCommands, resolveRootDir } from "./resolver.js";
import type { LspDiagnostic, SavedConfig } from "./types.js";
import {
  SEVERITY_ERROR,
  SEVERITY_WARNING,
  SEVERITY_INFO,
  SEVERITY_HINT,
} from "./types.js";
import { getOrCreateClient, handleLspError } from "./tool-result-helpers.js";
import { formatDiagnostics } from "./format.js";

const TOGGLE_LABEL = "Toggle LSP extension on/off";
const KILL_LABEL = "Kill active LSP server(s)";
const DETAILS_LABEL = "Show LSP details";
const CHECK_LABEL = "Check diagnostics";

const DIAGNOSTICS_TIMEOUT_IN_MS = 30_000;

/**
 * Check diagnostics for a file or directory and add to context if issues found
 */
async function handleCheck(
  lspClients: Map<string, LspClientEntry>,
  ctx: ExtensionContext,
  savedConfig: SavedConfig | null,
  pi?: ExtensionAPI,
): Promise<void> {
  const fileConfig = loadFileConfig();

  // Ask user for file or directory path
  const input = await ctx.ui.input("Enter file or directory path:");
  if (!input) return;

  const targetPath = path.resolve(ctx.cwd, input);

  // Check if path exists
  if (!fs.existsSync(targetPath)) {
    ctx.ui.notify(`Path not found: ${input}`, "error");
    return;
  }

  // Collect files to check
  const filesToCheck: string[] = [];
  const stat = fs.statSync(targetPath);

  if (stat.isDirectory()) {
    // Recursively find files in directory (excluding node_modules, .git, etc.)
    const walkDir = (dir: string) => {
      try {
        const entries = fs.readdirSync(dir, { withFileTypes: true });
        for (const entry of entries) {
          const fullPath = path.join(dir, entry.name);
          if (entry.isDirectory()) {
            // Skip common ignore directories
            if (
              !["node_modules", ".git", "dist", "build", ".next"].includes(
                entry.name,
              )
            ) {
              walkDir(fullPath);
            }
          } else if (entry.isFile()) {
            filesToCheck.push(fullPath);
          }
        }
      } catch (err) {
        // Silently skip directories we can't read
      }
    };
    walkDir(targetPath);
  } else {
    filesToCheck.push(targetPath);
  }

  if (filesToCheck.length === 0) {
    ctx.ui.notify("No files found to check", "warning");
    return;
  }

  // Group files by LSP server
  const filesByServer = new Map<string, string[]>();
  for (const file of filesToCheck) {
    const resolved = resolveLspCommands(
      [file],
      undefined,
      savedConfig,
      fileConfig,
    );
    if (resolved.length === 0) continue;

    // Use first matching server for each file
    const serverKey = resolved[0]!.command.join(" ");
    const existing = filesByServer.get(serverKey) ?? [];
    existing.push(file);
    filesByServer.set(serverKey, existing);
  }

  if (filesByServer.size === 0) {
    ctx.ui.notify("No LSP servers configured for these files", "warning");
    return;
  }

  ctx.ui.notify(
    `Checking diagnostics for ${filesToCheck.length} file(s)...`,
    "info",
  );

  // Collect all diagnostics
  const allDiagnostics = new Map<string, LspDiagnostic[]>();
  let totalErrors = 0;
  let totalWarnings = 0;
  let totalInfos = 0;
  let totalHints = 0;

  // Process each server's files
  for (const [serverKey, files] of filesByServer.entries()) {
    const resolved = resolveLspCommands(
      [files[0]!],
      undefined,
      savedConfig,
      fileConfig,
    )[0]!;
    const rootDir =
      resolved.rootMarkers.length > 0
        ? resolveRootDir(files[0]!, resolved.rootMarkers, ctx.cwd)
        : ctx.cwd;
    const commandKey = `${serverKey}::${rootDir}`;
    const lspBin = path.basename(resolved.command[0]!);

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

      const serverDiagnostics = await entry.client.getDiagnostics(
        files,
        ctx.cwd,
        DIAGNOSTICS_TIMEOUT_IN_MS,
        AbortSignal.timeout(DIAGNOSTICS_TIMEOUT_IN_MS),
      );

      // Merge diagnostics
      for (const [uri, diags] of serverDiagnostics) {
        const existing = allDiagnostics.get(uri) ?? [];
        allDiagnostics.set(uri, [...existing, ...diags]);

        // Count errors and warnings
        for (const diag of diags) {
          if (diag.severity === SEVERITY_ERROR) totalErrors++;
          else if (diag.severity === SEVERITY_WARNING) totalWarnings++;
          else if (diag.severity === SEVERITY_INFO) totalInfos++;
          else if (diag.severity === SEVERITY_HINT) totalHints++;
        }
      }

      setLspWidget(ctx, lspBin, "idle", serverDiagnostics);
    } catch (err) {
      handleLspError(err, commandKey, ctx, lspClients);
    }
  }

  // Add to context if there are issues
  if (totalErrors + totalWarnings + totalInfos + totalHints > 0) {
    const { text } = formatDiagnostics(allDiagnostics, ctx.cwd);
    const summary = `${totalErrors} error(s), ${totalWarnings} warning(s) ${totalInfos} info(s) ${totalHints} hint(s)`;
    const header = `--- LSP Diagnostics Check: ${summary} ---\n`;

    const diagnosticReport = header + text;

    // Inject to conversation context using sendMessage
    if (pi) {
      pi.sendMessage({
        customType: "lsp-diagnostics-check",
        content: diagnosticReport,
        display: true,
        details: {
          path: input,
          errorCount: totalErrors,
          warningCount: totalWarnings,
          fileCount: filesToCheck.length,
          timestamp: new Date().toISOString(),
        },
      });
    }
  } else {
    ctx.ui.notify(
      `✓ All good! No errors or warnings found in ${filesToCheck.length} file(s).`,
      "info",
    );
  }
}

/**
 * Main LSP command handler - shows a selection menu for all LSP actions
 */
export async function handleLspCommand(
  config: LspDiagnosticsConfig,
  lspClients: Map<string, LspClientEntry>,
  ctx: ExtensionContext,
  savedConfig: SavedConfig | null = null,
  pi?: ExtensionAPI,
): Promise<void> {
  const action = await ctx.ui.select("Select an LSP action:", [
    CHECK_LABEL,
    TOGGLE_LABEL,
    KILL_LABEL,
    DETAILS_LABEL,
  ]);

  if (!action) return;

  switch (action) {
    case CHECK_LABEL:
      await handleCheck(lspClients, ctx, savedConfig, pi);
      break;
    case TOGGLE_LABEL:
      await handleToggle(config, ctx);
      break;
    case KILL_LABEL:
      await handleKill(lspClients, ctx);
      break;
    case DETAILS_LABEL:
      await handleDetails(lspClients, ctx);
      break;
  }
}

/**
 * Toggle auto LSP diagnostics on/off for this session
 */
async function handleToggle(
  config: LspDiagnosticsConfig,
  ctx: ExtensionContext,
): Promise<void> {
  config.enabled = !config.enabled;
  saveEnabled(config.enabled);
  ctx.ui.notify(
    `lsp-diagnostics ${config.enabled ? "enabled" : "disabled"}`,
    "info",
  );
}

/**
 * Manually shut down one or all active LSP server(s)
 */
async function handleKill(
  lspClients: Map<string, LspClientEntry>,
  ctx: ExtensionContext,
): Promise<void> {
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
  const chosen = await ctx.ui.select("Select an LSP server to kill:", options);
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
}

/**
 * Show detailed debug info for all active LSP server(s) in an interactive TUI
 */
async function handleDetails(
  lspClients: Map<string, LspClientEntry>,
  ctx: ExtensionContext,
): Promise<void> {
  if (!ctx.hasUI) return;

  await ctx.ui.custom(
    (
      tui: TUI,
      theme: unknown,
      _kb: unknown,
      done: (result: unknown) => void,
    ) => {
      return new LspDetailsComponent(lspClients, tui, theme, done);
    },
    {
      overlay: true,
      overlayOptions: {
        width: "90%",
        minWidth: 80,
        maxHeight: "85%",
        anchor: "center",
        margin: 4,
      },
    },
  );
}
