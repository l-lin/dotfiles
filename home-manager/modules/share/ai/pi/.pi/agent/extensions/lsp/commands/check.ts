/**
 * Check diagnostics for a file or directory and add to context if issues found
 */
import type {
  ExtensionContext,
  ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import * as path from "node:path";
import * as fs from "node:fs";
import type { LspClientEntry, SavedConfig } from "../types.js";
import { LSP_SERVERS_CONFIG } from "../lsp-servers.js";
import { collectDiagnostics } from "../collector.js";
import { resolveTargetContext } from "../targets.js";
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

  const resolvedTarget = resolveTargetContext(
    input,
    ctx.cwd,
    savedConfig,
    fileConfig,
  );
  const filesToCheck = resolvedTarget.files;

  if (filesToCheck.length === 0) {
    ctx.ui.notify("No supported files found to check", "warning");
    return;
  }

  if (resolvedTarget.commands.length === 0) {
    ctx.ui.notify("No LSP servers configured for these files", "warning");
    return;
  }

  ctx.ui.notify(
    `Checking diagnostics for ${filesToCheck.length} file(s) with ${resolvedTarget.commands.length} server(s)...`,
    "info",
  );

  // Single collectDiagnostics call with all servers — this keeps all LSP
  // widget entries alive concurrently (syncLspServers sees the full list).
  const { merged } = await collectDiagnostics(
    filesToCheck,
    resolvedTarget.commands,
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
