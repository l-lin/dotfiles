/**
 * This module exports all the rendering functions.
 */

import { Text } from "@mariozechner/pi-tui";
import { homedir } from "os";
import { getBuiltInTools } from "./toolCache.js";
import type { FileMutationDiagnosticsEvent } from "../file-mutation-events/index.js";

/**
 * Shorten a path by replacing home directory with ~
 */
function shortenPath(path: string): string {
  const home = homedir();
  if (path.startsWith(home)) {
    return `~${path.slice(home.length)}`;
  }
  return path;
}

// ─── Read Tool Renders ──────────────────────────────────────────────────────

export function renderReadCall(args: any, theme: any) {
  const path = shortenPath(args.path || "");
  let pathDisplay = path
    ? theme.fg("accent", path)
    : theme.fg("toolOutput", "...");

  // Show line range if specified
  if (args.offset !== undefined || args.limit !== undefined) {
    const startLine = args.offset ?? 1;
    const endLine = args.limit !== undefined ? startLine + args.limit - 1 : "";
    pathDisplay += theme.fg(
      "warning",
      `:${startLine}${endLine ? `-${endLine}` : ""}`,
    );
  }

  const text = `${theme.fg("toolTitle", theme.bold("read"))} ${pathDisplay}`;
  return new Text(text, 0, 0);
}

export function renderReadResult(result: any, { expanded }: any, theme: any) {
  if (!expanded) return new Text("", 0, 0);
  const tools = getBuiltInTools(process.cwd());
  return tools.read.renderResult(result, { expanded }, theme);
}

// ─── Mutation Annotation Helper ─────────────────────────────────────────────

/**
 * Returns a lightweight reactive component for collapsed write/edit results.
 *
 * The component reads from the live `diagnosticsCache` map on every `render()`
 * call, so it automatically shows fresh data whenever pi re-renders the
 * conversation (e.g. after `tui.requestRender()` is triggered by the event
 * listener in index.ts).
 *
 * No coupling to lsp-diagnostics: all data arrives via the
 * FILE_MUTATION_DIAGNOSTICS_CHANNEL contract from file-mutation-events.
 */
function makeMutationAnnotation(
  cache: Map<string, FileMutationDiagnosticsEvent>,
  filePath: string,
  theme: any,
) {
  return {
    render(_width: number): string[] {
      const event = cache.get(filePath);
      if (!event?.summary) return [];
      return [theme.fg("muted", ` ${event.summary}`)];
    },
    invalidate() {},
  };
}

// ─── Write Tool Renders ─────────────────────────────────────────────────────

export function renderWriteCall(args: any, theme: any) {
  const path = shortenPath(args.path || "");
  const pathDisplay = path
    ? theme.fg("accent", path)
    : theme.fg("toolOutput", "...");
  const lineCount = args.content ? args.content.split("\n").length : 0;
  const lineInfo =
    lineCount > 0 ? theme.fg("muted", ` (${lineCount} lines)`) : "";

  const text = `${theme.fg("toolTitle", theme.bold("write"))} ${pathDisplay}${lineInfo}`;
  return new Text(text, 0, 0);
}

export function renderWriteResult(
  result: any,
  { expanded }: any,
  theme: any,
  cache: Map<string, FileMutationDiagnosticsEvent>,
  filePath: string,
) {
  if (!expanded) return makeMutationAnnotation(cache, filePath, theme);
  const tools = getBuiltInTools(process.cwd());
  return tools.write.renderResult(result, { expanded }, theme);
}

// ─── Edit Tool Renders ──────────────────────────────────────────────────────

export function renderEditCall(args: any, theme: any) {
  const path = shortenPath(args.path || "");
  const pathDisplay = path
    ? theme.fg("accent", path)
    : theme.fg("toolOutput", "...");

  const text = `${theme.fg("toolTitle", theme.bold("edit"))} ${pathDisplay}`;
  return new Text(text, 0, 0);
}

export function renderEditResult(
  result: any,
  { expanded }: any,
  theme: any,
  cache: Map<string, FileMutationDiagnosticsEvent>,
  filePath: string,
) {
  if (!expanded) return makeMutationAnnotation(cache, filePath, theme);
  const tools = getBuiltInTools(process.cwd());
  return tools.edit.renderResult(result, { expanded }, theme);
}

// ─── Find Tool Renders ──────────────────────────────────────────────────────

export function renderFindCall(args: any, theme: any) {
  const pattern = args.pattern || "";
  const path = shortenPath(args.path || ".");
  const limit = args.limit;

  let text = `${theme.fg("toolTitle", theme.bold("find"))} ${theme.fg("accent", pattern)}`;
  text += theme.fg("toolOutput", ` in ${path}`);
  if (limit !== undefined) {
    text += theme.fg("toolOutput", ` (limit ${limit})`);
  }

  return new Text(text, 0, 0);
}

export function renderFindResult(result: any, { expanded }: any, theme: any) {
  if (!expanded) {
    // Minimal: just show count
    const textContent = result.content.find((c: any) => c.type === "text");
    if (textContent?.type === "text") {
      const count = textContent.text.trim().split("\n").filter(Boolean).length;
      if (count > 0) {
        return new Text(theme.fg("muted", ` → ${count} files`), 0, 0);
      }
    }
    return new Text("", 0, 0);
  }

  const tools = getBuiltInTools(process.cwd());
  return tools.find.renderResult(result, { expanded }, theme);
}

// ─── Grep Tool Renders ──────────────────────────────────────────────────────

export function renderGrepCall(args: any, theme: any) {
  const pattern = args.pattern || "";
  const path = shortenPath(args.path || ".");
  const glob = args.glob;
  const limit = args.limit;

  let text = `${theme.fg("toolTitle", theme.bold("grep"))} ${theme.fg("accent", `/${pattern}/`)}`;
  text += theme.fg("toolOutput", ` in ${path}`);
  if (glob) {
    text += theme.fg("toolOutput", ` (${glob})`);
  }
  if (limit !== undefined) {
    text += theme.fg("toolOutput", ` limit ${limit}`);
  }

  return new Text(text, 0, 0);
}

export function renderGrepResult(result: any, { expanded }: any, theme: any) {
  if (!expanded) {
    // Minimal: just show match count
    const textContent = result.content.find((c: any) => c.type === "text");
    if (textContent?.type === "text") {
      const count = textContent.text.trim().split("\n").filter(Boolean).length;
      if (count > 0) {
        return new Text(theme.fg("muted", ` → ${count} matches`), 0, 0);
      }
    }
    return new Text("", 0, 0);
  }

  const tools = getBuiltInTools(process.cwd());
  return tools.grep.renderResult(result, { expanded }, theme);
}

// ─── Ls Tool Renders ────────────────────────────────────────────────────────

export function renderLsCall(args: any, theme: any) {
  const path = shortenPath(args.path || ".");
  const limit = args.limit;

  let text = `${theme.fg("toolTitle", theme.bold("ls"))} ${theme.fg("accent", path)}`;
  if (limit !== undefined) {
    text += theme.fg("toolOutput", ` (limit ${limit})`);
  }

  return new Text(text, 0, 0);
}

export function renderLsResult(result: any, { expanded }: any, theme: any) {
  if (!expanded) {
    // Minimal: just show entry count
    const textContent = result.content.find((c: any) => c.type === "text");
    if (textContent?.type === "text") {
      const count = textContent.text.trim().split("\n").filter(Boolean).length;
      if (count > 0) {
        return new Text(theme.fg("muted", ` → ${count} entries`), 0, 0);
      }
    }
    return new Text("", 0, 0);
  }

  const tools = getBuiltInTools(process.cwd());
  return tools.ls.renderResult(result, { expanded }, theme);
}

// ─── Bash Tool Renders (for rtk-rewrite) ───────────────────────────────────

export function renderBashCall(args: any, theme: any) {
  const command = args.command || "...";
  const timeout = args.timeout as number | undefined;
  const timeoutSuffix = timeout
    ? theme.fg("muted", ` (timeout ${timeout}s)`)
    : "";

  const text =
    theme.fg("toolTitle", theme.bold(`$ ${command}`)) + timeoutSuffix;
  return new Text(text, 0, 0);
}

export function renderBashResult(result: any, { expanded }: any, theme: any) {
  if (!expanded) return new Text("", 0, 0);
  const tools = getBuiltInTools(process.cwd());
  return tools.bash.renderResult(result, { expanded }, theme);
}
