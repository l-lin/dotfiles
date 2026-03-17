/**
 * Check diagnostics for a file or directory and add to context if issues found
 */
import type {
  ExtensionContext,
  ExtensionAPI,
} from "@mariozechner/pi-coding-agent";
import * as path from "node:path";
import * as fs from "node:fs";
import type { LspClientEntry, SavedConfig } from "../types.js";
import { LSP_SERVERS_CONFIG } from "../lsp-servers.js";
import type { ResolvedLspCommand } from "../resolver.js";
import { resolveLspCommands } from "../resolver.js";
import { collectDiagnostics } from "../collector.js";
import { formatDiagnostics } from "../ui/format.js";

const IGNORED_DIRS = new Set([
  "node_modules",
  ".git",
  "dist",
  "build",
  ".next",
]);

function collectFiles(dir: string): string[] {
  const files: string[] = [];
  try {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory() && !IGNORED_DIRS.has(entry.name)) {
        files.push(...collectFiles(fullPath));
      } else if (entry.isFile()) {
        files.push(fullPath);
      }
    }
  } catch {
    // Skip directories we can't read
  }
  return files;
}

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

  const stat = fs.statSync(targetPath);
  const filesToCheck = stat.isDirectory()
    ? collectFiles(targetPath)
    : [targetPath];

  if (filesToCheck.length === 0) {
    ctx.ui.notify("No files found to check", "warning");
    return;
  }

  // Collect unique resolved LSP servers across all files.
  // We gather one entry per distinct server command so that collectDiagnostics
  // can fan-out to ALL matching servers in a single Promise.all, keeping the
  // widget in sync for every server simultaneously.
  const serverMap = new Map<string, ResolvedLspCommand>();
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
  const { merged } = await collectDiagnostics(
    filesToCheck,
    [...serverMap.values()],
    lspClients,
    ctx,
  );

  const { text, errorCount, warningCount, infoCount, hintCount } =
    formatDiagnostics(merged, ctx.cwd);
  const totalIssues = errorCount + warningCount + infoCount + hintCount;

  if (totalIssues > 0) {
    const summary = `${errorCount} error(s), ${warningCount} warning(s) ${infoCount} info(s) ${hintCount} hint(s)`;
    const header = `--- LSP Diagnostics Check: ${summary} ---\n`;

    if (pi) {
      pi.sendMessage({
        customType: "lsp-diagnostics-check",
        content: header + text,
        display: true,
        details: {
          path: input,
          errorCount,
          warningCount,
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
