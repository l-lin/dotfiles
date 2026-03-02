import * as path from "node:path";
import type { LspDiagnostic } from "./types.js";
import { SEVERITY_LABELS } from "./types.js";
import { fileUriToPath } from "./resolver.js";

/**
 * Formats diagnostics as `path/to/file.ts:line:col [severity] message` lines.
 */
export function formatDiagnostics(
  allDiagnostics: Map<string, LspDiagnostic[]>,
  cwd: string,
): { text: string; errorCount: number; warningCount: number } {
  let errorCount = 0;
  let warningCount = 0;
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
    }
  }

  return { text: lines.join("\n"), errorCount, warningCount };
}
