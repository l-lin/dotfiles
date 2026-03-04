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
 * `summary` is null when there are no diagnostics to report.
 * Full diagnostic details are appended directly to the tool result content by
 * the emitter so the LLM sees them and the built-in renderResult displays them
 * in expanded view — no need to carry them in this event.
 */
export interface WriteToolDiagnosticsEvent {
  /** Absolute or cwd-relative path of the file that was written/edited. */
  filePath: string;
  /**
   * Short plain-text summary suitable for a single collapsed line.
   * e.g. "✖ 2  ⚠ 1  ℹ 3"
   */
  summary: string | null;
}

export default function (pi: ExtensionAPI) {}
