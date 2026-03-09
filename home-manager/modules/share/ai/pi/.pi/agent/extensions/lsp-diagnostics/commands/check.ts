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

  // Group files by LSP server
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

  const allDiagnostics = new Map<string, LspDiagnostic[]>();
  let totalErrors = 0;
  let totalWarnings = 0;
  let totalInfos = 0;
  let totalHints = 0;

  for (const { files, resolved } of serverGroups.values()) {
    const { merged } = await collectDiagnostics(
      [...files],
      [resolved],
      lspClients,
      ctx,
    );

    for (const [uri, diags] of merged) {
      const existing = allDiagnostics.get(uri) ?? [];
      allDiagnostics.set(uri, [...existing, ...diags]);

      for (const diag of diags) {
        if (diag.severity === SEVERITY_ERROR) totalErrors++;
        else if (diag.severity === SEVERITY_WARNING) totalWarnings++;
        else if (diag.severity === SEVERITY_INFO) totalInfos++;
        else if (diag.severity === SEVERITY_HINT) totalHints++;
      }
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
