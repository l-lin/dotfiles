/**
 * This module exports all the rendering functions.
 */

import { Text } from "@mariozechner/pi-tui";
import { renderDiff } from "@mariozechner/pi-coding-agent";
import { homedir } from "os";
import { getBuiltInTools } from "./tool-cache.js";

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

// =========================================================================
// Read Tool
// =========================================================================
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

const MAX_DISPLAY_LINES = 50;

export function renderReadResult(result: any, { expanded }: any, theme: any) {
  if (!expanded) return new Text("", 0, 0);

  const textContent = result.content?.find((c: any) => c.type === "text");
  if (!textContent) return new Text("", 0, 0);

  const lines = textContent.text.split("\n");
  const truncated = lines.length > MAX_DISPLAY_LINES;
  const displayLines = truncated ? lines.slice(0, MAX_DISPLAY_LINES) : lines;

  let text = displayLines
    .map((l: string) => theme.fg("toolOutput", l))
    .join("\n");
  if (truncated) {
    text += `\n${theme.fg("muted", `... (${lines.length - MAX_DISPLAY_LINES} more lines hidden)`)}`;
  }

  return new Text(text, 0, 0);
}

// =========================================================================
// Write Tool
// =========================================================================
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

export function renderWriteResult(result: any, { expanded }: any, theme: any) {
  if (!expanded) return new Text("", 0, 0);
  const tools = getBuiltInTools(process.cwd());
  return tools.write.renderResult(result, { expanded }, theme);
}

// =========================================================================
// Edit Tool
// =========================================================================
export function renderEditCall(args: any, theme: any) {
  const path = shortenPath(args.path || "");
  const pathDisplay = path
    ? theme.fg("accent", path)
    : theme.fg("toolOutput", "...");

  const text = `${theme.fg("toolTitle", theme.bold("edit"))} ${pathDisplay}`;
  return new Text(text, 0, 0);
}

export function renderEditResult(result: any, { expanded }: any, theme: any) {
  if (!expanded) return new Text("", 0, 0);

  // Try to extract diff from result
  const diff = result.details?.diff;
  if (typeof diff === "string" && diff.length > 0) {
    return new Text(renderDiff(diff), 0, 0);
  }

  const tools = getBuiltInTools(process.cwd());
  return tools.edit.renderResult(result, { expanded }, theme);
}

// =========================================================================
// Find Tool
// =========================================================================
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

// =========================================================================
// Grep Tool
// =========================================================================
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

// =========================================================================
// LS Tool
// =========================================================================
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

// =========================================================================
// Bash Tool
// =========================================================================
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
