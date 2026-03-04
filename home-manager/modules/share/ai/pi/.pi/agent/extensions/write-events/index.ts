/**
 * write-events — shared contract for write/edit tool event bus messages.
 *
 * This module is a pure contract library: no extension logic, no pi API usage.
 * It exports event types and channel names for extensions that emit or subscribe
 * to write/edit lifecycle events.
 *
 * Dependents:
 *   - lsp-diagnostics: emits WRITE_TOOL_DIAGNOSTICS_CHANNEL after every write/edit
 *   - minimal-mode:    subscribes to render the summary and full details
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

// ─── Diagnostics event ────────────────────────────────────────────────────────

/** pi.events channel name for diagnostic results produced after a write/edit. */
export const WRITE_TOOL_DIAGNOSTICS_CHANNEL = "write-events:diagnostics";

/**
 * Payload emitted on `WRITE_TOOL_DIAGNOSTICS_CHANNEL` after a write/edit
 * that produces diagnostics.
 *
 * All content is pre-formatted by the emitter. Subscribers render the strings
 * as-is without needing to understand the underlying diagnostic format.
 *
 * Both `summary` and `details` are null when there are no diagnostics to report.
 */
export interface WriteToolDiagnosticsEvent {
  /** Absolute or cwd-relative path of the file that was written/edited. */
  filePath: string;
  /**
   * Short plain-text summary suitable for a single collapsed line.
   * e.g. "✖ 2  ⚠ 1  ℹ 3"
   */
  summary: string | null;
  /**
   * Full plain-text diagnostic output for the expanded view.
   * e.g. the LSP diagnostic block with file, line, and message details.
   */
  details: string | null;
}

export default function (pi: ExtensionAPI) {}
