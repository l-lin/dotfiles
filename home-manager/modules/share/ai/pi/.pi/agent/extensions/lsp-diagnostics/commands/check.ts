/**
 * Check diagnostics for a file or directory and add to context if issues found
 */
import type {
  ExtensionContext,
  ExtensionAPI,
} from "@mariozechner/pi-coding-agent";
import * as path from "node:path";
import * as fs from "node:fs";
import type { LspClientEntry } from "../lsp-details.js";
import { setLspWidget } from "../widget.js";
import { loadFileConfig } from "../config.js";
import { resolveLspCommands, resolveRootDir } from "../resolver.js";
import type { LspDiagnostic, SavedConfig } from "../types.js";
import {
  SEVERITY_ERROR,
  SEVERITY_WARNING,
  SEVERITY_INFO,
  SEVERITY_HINT,
} from "../types.js";
import { getOrCreateClient, handleLspError } from "../tool-result-helpers.js";
import { formatDiagnostics } from "../format.js";

const DIAGNOSTICS_TIMEOUT_IN_MS = 5_000;

/**
 * Check diagnostics for a file or directory
 * @param filePath - Optional path to check. If not provided, prompts the user.
 */
export async function handleCheck(
  lspClients: Map<string, LspClientEntry>,
  ctx: ExtensionContext,
  savedConfig: SavedConfig | null,
  pi?: ExtensionAPI,
  filePath?: string,
): Promise<void> {
  const fileConfig = loadFileConfig();

  // Use provided path or ask user for file or directory path
  const input =
    filePath ?? (await ctx.ui.input("Enter file or directory path:"));
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

  // Group files by LSP server, storing both files and resolved config
  const serverGroups = new Map<
    string,
    { files: string[]; resolved: ReturnType<typeof resolveLspCommands>[0] }
  >();
  for (const file of filesToCheck) {
    const resolved = resolveLspCommands(
      [file],
      undefined,
      savedConfig,
      fileConfig,
    );
    if (resolved.length === 0) continue;

    // Use ALL matching servers for each file
    for (const resolvedServer of resolved) {
      const serverKey = resolvedServer.command.join(" ");
      const existing = serverGroups.get(serverKey);
      if (existing) {
        existing.files.push(file);
      } else {
        serverGroups.set(serverKey, {
          files: [file],
          resolved: resolvedServer,
        });
      }
    }
  }

  if (serverGroups.size === 0) {
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
  for (const [serverKey, { files, resolved }] of serverGroups.entries()) {
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

      const result = await entry.client.getDiagnostics(
        files,
        ctx.cwd,
        DIAGNOSTICS_TIMEOUT_IN_MS,
        AbortSignal.timeout(DIAGNOSTICS_TIMEOUT_IN_MS),
      );

      const serverDiagnostics = result.diagnostics;

      // Build timing info
      const timing = {
        initDurationMs: entry.client.initDurationMs,
        lastCheckDurationMs: result.durationMs,
        receivedResponse: result.receivedResponse,
      };

      // Log timing info
      if (!result.receivedResponse) {
        ctx.ui.notify(
          `lsp-diagnostics: ${lspBin} timed out after ${result.durationMs}ms (${result.urisResolved}/${result.urisRequested} files)`,
          "warning",
        );
      }

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

      setLspWidget(ctx, lspBin, "idle", serverDiagnostics, timing);
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
