/**
 * Helper functions for the tool_result event handler.
 */
import * as path from "node:path";
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import {
  truncateHead,
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
} from "@mariozechner/pi-coding-agent";
import type { LspDiagnostic } from "./types.js";
import { SEVERITY_ERROR, SEVERITY_WARNING, SEVERITY_INFO } from "./types.js";
import type { LspClientEntry } from "./lsp-debug.js";
import { PersistentLspClient } from "./lsp-client.js";
import { formatDiagnostics } from "./format.js";
import { resolveLspCommand } from "./resolver.js";
import { setLspWidget, clearWidget } from "./widget.js";

export async function getOrCreateClient(
  resolved: NonNullable<ReturnType<typeof resolveLspCommand>>,
  rootDir: string,
  commandKey: string,
  lspBin: string,
  ctx: ExtensionContext,
  lspClients: Map<string, LspClientEntry>,
): Promise<LspClientEntry> {
  setLspWidget(ctx, lspBin, "starting");

  let entry = lspClients.get(commandKey);
  if (entry) return entry;

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
  return entry;
}

export function handleLspError(
  err: unknown,
  commandKey: string,
  ctx: ExtensionContext,
  lspClients: Map<string, LspClientEntry>,
): void {
  lspClients.delete(commandKey);
  if (lspClients.size === 0) {
    clearWidget(ctx);
  } else {
    const [survivingEntry] = lspClients.values();
    setLspWidget(ctx, survivingEntry!.bin, "idle");
  }
  const msg = err instanceof Error ? err.message : String(err);
  ctx.ui.notify(`lsp-diagnostics: ${msg}`, "warning");
}

export function buildDiagnosticBlock(
  diagnostics: Map<string, LspDiagnostic[]>,
  filePath: string,
  lspBin: string,
  cwd: string,
): string | null {
  const { text, errorCount, warningCount } = formatDiagnostics(
    diagnostics,
    cwd,
  );
  if (errorCount === 0 && warningCount === 0) return null;

  const relPath = path.relative(cwd, path.resolve(cwd, filePath));
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

  let block = truncation.content;
  if (truncation.truncated) {
    block += `\n[Output truncated: ${truncation.outputLines}/${truncation.totalLines} lines shown]`;
  }
  return block;
}

/**
 * Count errors and warnings across all files in a diagnostics map.
 * Extracted as a standalone helper so it can be called before building the
 * full text block (needed for the event-bus broadcast).
 */
export function extractDiagnosticSummary(
  diagnostics: Map<string, LspDiagnostic[]>,
): { errorCount: number; warningCount: number; infoCount: number } {
  let errorCount = 0;
  let warningCount = 0;
  let infoCount = 0;
  for (const diags of diagnostics.values()) {
    for (const d of diags) {
      if (d.severity === SEVERITY_ERROR) errorCount++;
      else if (d.severity === SEVERITY_WARNING) warningCount++;
      else if (d.severity === SEVERITY_INFO) infoCount++;
    }
  }
  return { errorCount, warningCount, infoCount };
}

export function appendToContent(
  existing: Array<{ type: string; text?: string }> | undefined,
  diagnosticBlock: string,
) {
  const content = [...(existing ?? [])];
  if (content.length === 0) {
    content.push({ type: "text", text: diagnosticBlock });
  } else {
    const last = content[content.length - 1]!;
    content[content.length - 1] = {
      ...last,
      text: (last.text ?? "") + diagnosticBlock,
    };
  }
  return content;
}
