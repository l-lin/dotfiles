/**
 * Minimal Mode Example - Demonstrates a "minimal" tool display mode
 *
 * This extension overrides built-in tools to provide custom rendering:
 * - Collapsed mode: Only shows the tool call (command/path), no output
 * - Expanded mode: Shows full output like the built-in renderers
 *
 * This demonstrates how a "minimal mode" could work, where ctrl+o cycles through:
 * - Standard: Shows truncated output (current default)
 * - Expanded: Shows full output (current expanded)
 * - Minimal: Shows only tool call, no output (this extension's collapsed mode)
 *
 * Usage:
 *   pi -e ./minimal-mode.ts
 *
 * Then use ctrl+o to toggle between minimal (collapsed) and full (expanded) views.
 *
 * src: https://github.com/badlogic/pi-mono/blob/3a3e37d39014acc4269171be2a51518f6a71be1f/packages/coding-agent/examples/extensions/minimal-mode.ts
 * Adapted to remove the bash tool override as it's used by rtk-rewrite extension.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
  renderReadCall,
  renderReadResult,
  renderWriteCall,
  renderWriteResult,
  renderEditCall,
  renderEditResult,
  renderFindCall,
  renderFindResult,
  renderGrepCall,
  renderGrepResult,
  renderLsCall,
  renderLsResult,
} from "./renders.js";
import { getBuiltInTools } from "./toolCache.js";
import { FILE_MUTATION_DIAGNOSTICS_CHANNEL } from "../file-mutation-events/index.js";
import type { FileMutationDiagnosticsEvent } from "../file-mutation-events/index.js";

export default function (pi: ExtensionAPI) {
  /**
   * Cache of the latest LSP diagnostics summary per file path.
   * Populated via the FILE_MUTATION_DIAGNOSTICS_CHANNEL event (file-mutation-events contract).
   * Keyed by the filePath from the event (as-is, no normalization needed — it
   * matches the path passed to write/edit).
   */
  const diagnosticsCache = new Map<string, FileMutationDiagnosticsEvent>();

  pi.events.on(FILE_MUTATION_DIAGNOSTICS_CHANNEL, (data) => {
    const event = data as FileMutationDiagnosticsEvent;
    diagnosticsCache.set(event.filePath, event);
  });

  // =========================================================================
  // Read Tool
  // =========================================================================
  pi.registerTool({
    name: "read",
    label: "read",
    description:
      "Read the contents of a file. Supports text files and images (jpg, png, gif, webp). Images are sent as attachments. For text files, output is truncated to 2000 lines or 50KB (whichever is hit first). Use offset/limit for large files.",
    parameters: getBuiltInTools(process.cwd()).read.parameters,

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const tools = getBuiltInTools(ctx.cwd);
      return tools.read.execute(toolCallId, params, signal, onUpdate);
    },

    renderCall(args, theme) {
      return renderReadCall(args, theme);
    },

    renderResult(result, { expanded }, theme) {
      return renderReadResult(result, { expanded }, theme);
    },
  });

  // =========================================================================
  // Write Tool
  // =========================================================================
  // The pi render API does not expose toolCallId to renderCall/renderResult,
  // so we cannot key by invocation ID. We use a FIFO queue instead: renderCall
  // enqueues the path, renderResult dequeues it. Under sequential calls this is
  // exact. Under parallel calls of the same tool type it degrades to FIFO order
  // (still deterministic, never cross-contaminates with *other* tools).
  const writePathQueue: string[] = [];

  pi.registerTool({
    name: "write",
    label: "write",
    description:
      "Write content to a file. Creates the file if it doesn't exist, overwrites if it does. Automatically creates parent directories.",
    parameters: getBuiltInTools(process.cwd()).write.parameters,

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const tools = getBuiltInTools(ctx.cwd);
      return tools.write.execute(toolCallId, params, signal, onUpdate);
    },

    renderCall(args, theme) {
      writePathQueue.push(args.path ?? "");
      return renderWriteCall(args, theme);
    },

    renderResult(result, { expanded }, theme) {
      const filePath = writePathQueue.shift() ?? "";
      return renderWriteResult(
        result,
        { expanded },
        theme,
        diagnosticsCache.get(filePath),
      );
    },
  });

  // =========================================================================
  // Edit Tool
  // =========================================================================
  const editPathQueue: string[] = [];

  pi.registerTool({
    name: "edit",
    label: "edit",
    description:
      "Edit a file by replacing exact text. The oldText must match exactly (including whitespace). Use this for precise, surgical edits.",
    parameters: getBuiltInTools(process.cwd()).edit.parameters,

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const tools = getBuiltInTools(ctx.cwd);
      return tools.edit.execute(toolCallId, params, signal, onUpdate);
    },

    renderCall(args, theme) {
      editPathQueue.push(args.path ?? "");
      return renderEditCall(args, theme);
    },

    renderResult(result, { expanded }, theme) {
      const filePath = editPathQueue.shift() ?? "";
      return renderEditResult(
        result,
        { expanded },
        theme,
        diagnosticsCache.get(filePath),
      );
    },
  });

  // =========================================================================
  // Find Tool
  // =========================================================================
  pi.registerTool({
    name: "find",
    label: "find",
    description:
      "Find files by name pattern (glob). Searches recursively from the specified path. Output limited to 200 results.",
    parameters: getBuiltInTools(process.cwd()).find.parameters,

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const tools = getBuiltInTools(ctx.cwd);
      return tools.find.execute(toolCallId, params, signal, onUpdate);
    },

    renderCall(args, theme) {
      return renderFindCall(args, theme);
    },

    renderResult(result, { expanded }, theme) {
      return renderFindResult(result, { expanded }, theme);
    },
  });

  // =========================================================================
  // Grep Tool
  // =========================================================================
  pi.registerTool({
    name: "grep",
    label: "grep",
    description:
      "Search file contents by regex pattern. Uses ripgrep for fast searching. Output limited to 200 matches.",
    parameters: getBuiltInTools(process.cwd()).grep.parameters,

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const tools = getBuiltInTools(ctx.cwd);
      return tools.grep.execute(toolCallId, params, signal, onUpdate);
    },

    renderCall(args, theme) {
      return renderGrepCall(args, theme);
    },

    renderResult(result, { expanded }, theme) {
      return renderGrepResult(result, { expanded }, theme);
    },
  });

  // =========================================================================
  // Ls Tool
  // =========================================================================
  pi.registerTool({
    name: "ls",
    label: "ls",
    description:
      "List directory contents with file sizes. Shows files and directories with their sizes. Output limited to 500 entries.",
    parameters: getBuiltInTools(process.cwd()).ls.parameters,

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const tools = getBuiltInTools(ctx.cwd);
      return tools.ls.execute(toolCallId, params, signal, onUpdate);
    },

    renderCall(args, theme) {
      return renderLsCall(args, theme);
    },

    renderResult(result, { expanded }, theme) {
      return renderLsResult(result, { expanded }, theme);
    },
  });
}
