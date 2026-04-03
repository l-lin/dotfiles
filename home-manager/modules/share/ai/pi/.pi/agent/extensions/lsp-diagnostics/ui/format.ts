import * as path from "node:path";
import type { LspDiagnostic } from "../types.js";
import { SEVERITY_LABELS } from "../types.js";
import { fileUriToPath } from "../resolver.js";

/**
 * Formats diagnostics as `path/to/file.ts:line:col [severity] message` lines.
 */
export function formatDiagnostics(
  allDiagnostics: Map<string, LspDiagnostic[]>,
  cwd: string,
): {
  text: string;
  errorCount: number;
  warningCount: number;
  infoCount: number;
  hintCount: number;
} {
  let errorCount = 0;
  let warningCount = 0;
  let infoCount = 0;
  let hintCount = 0;
  const lines: string[] = [];

  for (const [uri, diagnostics] of allDiagnostics) {
    const relPath = path.relative(cwd, fileUriToPath(uri));

    if (diagnostics.length === 0) {
      lines.push(`${relPath}: no diagnostics`);
      continue;
    }

    for (const d of diagnostics) {
      const line = d.range.start.line + 1;
      const col = d.range.start.character + 1;
      const severity = SEVERITY_LABELS[d.severity ?? 1] ?? "error";
      const source = d.source ? `(${d.source}) ` : "";
      const code = d.code != null ? `[${d.code}] ` : "";
      lines.push(
        `${relPath}:${line}:${col} [${severity}] ${source}${code}${d.message}`,
      );

      if ((d.severity ?? 1) === 1) errorCount++;
      else if (d.severity === 2) warningCount++;
      else if (d.severity === 3) infoCount++;
      else if (d.severity === 4) hintCount++;
    }
  }

  return {
    text: lines.join("\n"),
    errorCount,
    warningCount,
    infoCount,
    hintCount,
  };
}

import {
  truncateHead,
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
} from "@mariozechner/pi-coding-agent";

export function buildDiagnosticBlock(
  diagnostics: Map<string, LspDiagnostic[]>,
  filePath: string,
  lspBin: string,
  cwd: string,
): string | null {
  const { text, errorCount, warningCount, infoCount, hintCount } =
    formatDiagnostics(diagnostics, cwd);
  if (errorCount + warningCount + infoCount + hintCount === 0) return null;

  const relPath = path.relative(cwd, path.resolve(cwd, filePath));
  const summary = `${errorCount} error(s), ${warningCount} warning(s) ${infoCount} info(s)`;
  const header =
    `--- LSP Diagnostics (${lspBin}) ${summary} ---\n` +
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
