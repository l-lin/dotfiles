/**
 * Check diagnostics for a file or directory and add to context if issues found
 */
import type {
  ExtensionContext,
  ExtensionAPI,
} from "@mariozechner/pi-coding-agent";
import * as path from "node:path";
import * as fs from "node:fs";
import type { LspClientEntry, LspDiagnostic, SavedConfig } from "../types.js";
import {
  SEVERITY_ERROR,
  SEVERITY_WARNING,
  SEVERITY_INFO,
  SEVERITY_HINT,
} from "../types.js";
import { LSP_SERVERS_CONFIG } from "../lsp-diagnostics.js";
import { resolveLspCommands } from "../resolver.js";
import { collectDiagnostics } from "../collector.js";
import { formatDiagnostics } from "../ui/format.js";

/**
 * Check diagnostics for a file or directory.
 */
export async function handleCheck(
  lspClients: Map<string, LspClientEntry>,
  ctx: ExtensionContext,
  savedConfig: SavedConfig | null,
  pi?: ExtensionAPI,
  filePath?: string,
): Promise<void> {
  const fileConfig = LSP_SERVERS_CONFIG;

  const input =
    filePath ?? (await ctx.ui.input("Enter file or directory path:"));
  if (!input) return;

  const targetPath = path.resolve(ctx.cwd, input);

  if (!fs.existsSync(targetPath)) {
    ctx.ui.notify(`Path not found: ${input}`, "error");
    return;
  }

  const filesToCheck: string[] = [];
  const stat = fs.statSync(targetPath);

  if (stat.isDirectory()) {
    const walkDir = (dir: string) => {
      try {
        const entries = fs.readdirSync(dir, { withFileTypes: true });
        for (const entry of entries) {
          const fullPath = path.join(dir, entry.name);
          if (entry.isDirectory()) {
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
      } catch {
        // Skip directories we can't read
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

  // Collect unique resolved LSP servers across all files.
  // We gather one entry per distinct server command so that collectDiagnostics
  // can fan-out to ALL matching servers in a single Promise.all, keeping the
  // widget in sync for every server simultaneously.
  const serverMap = new Map<string, ReturnType<typeof resolveLspCommands>[0]>();
  for (const file of filesToCheck) {
    const resolved = resolveLspCommands(
      [file],
      undefined,
      savedConfig,
      fileConfig,
    );
    for (const resolvedServer of resolved) {
      const serverKey = resolvedServer.command.join(" ");
      if (!serverMap.has(serverKey)) {
        serverMap.set(serverKey, resolvedServer);
      }
    }
  }

  if (serverMap.size === 0) {
    ctx.ui.notify("No LSP servers configured for these files", "warning");
    return;
  }

  ctx.ui.notify(
    `Checking diagnostics for ${filesToCheck.length} file(s) with ${serverMap.size} server(s)...`,
    "info",
  );

  // Single collectDiagnostics call with all servers — this keeps all LSP
  // widget entries alive concurrently (syncLspServers sees the full list).
  const { merged: allDiagnosticsRaw } = await collectDiagnostics(
    filesToCheck,
    [...serverMap.values()],
    lspClients,
    ctx,
  );

  const allDiagnostics = new Map<string, LspDiagnostic[]>();
  let totalErrors = 0;
  let totalWarnings = 0;
  let totalInfos = 0;
  let totalHints = 0;

  for (const [uri, diags] of allDiagnosticsRaw) {
    allDiagnostics.set(uri, diags);
    for (const diag of diags) {
      if (diag.severity === SEVERITY_ERROR) totalErrors++;
      else if (diag.severity === SEVERITY_WARNING) totalWarnings++;
      else if (diag.severity === SEVERITY_INFO) totalInfos++;
      else if (diag.severity === SEVERITY_HINT) totalHints++;
    }
  }

  if (totalErrors + totalWarnings + totalInfos + totalHints > 0) {
    const { text } = formatDiagnostics(allDiagnostics, ctx.cwd);
    const summary = `${totalErrors} error(s), ${totalWarnings} warning(s) ${totalInfos} info(s) ${totalHints} hint(s)`;
    const header = `--- LSP Diagnostics Check: ${summary} ---\n`;

    if (pi) {
      pi.sendMessage({
        customType: "lsp-diagnostics-check",
        content: header + text,
        display: true,
        details: {
          path: input,
          errorCount: totalErrors,
          warningCount: totalWarnings,
          fileCount: filesToCheck.length,
          timestamp: new Date().toISOString(),
        },
      });
    } else {
      ctx.ui.notify(header + text, "warning");
    }
  } else {
    ctx.ui.notify(
      `✓ All good! No errors or warnings found in ${filesToCheck.length} file(s).`,
      "info",
    );
  }
}
