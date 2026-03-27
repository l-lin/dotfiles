import type {
  EditToolDetails,
  ToolRenderResultOptions,
} from "@mariozechner/pi-coding-agent";
import { renderDiff } from "@mariozechner/pi-coding-agent";
import { Component, Text } from "@mariozechner/pi-tui";
import { type BuiltInTools, getBuiltInTools } from "./tool-cache.js";

/** Returns a collapsed count summary (e.g. "→ 5 files") or empty text. */
function renderCollapsedCount(result: any, theme: any, label: string): Text {
  const textContent = result.content.find((c: any) => c.type === "text");
  const count =
    textContent?.text.trim().split("\n").filter(Boolean).length ?? 0;

  return new Text(
    count > 0 ? theme.fg("muted", ` → ${count} ${label}`) : "",
    0,
    0,
  );
}

function renderBuiltInResult(
  toolName: keyof BuiltInTools,
  result: any,
  options: ToolRenderResultOptions,
  theme: any,
  context: any,
): Component {
  const renderResult = getBuiltInTools(context.cwd)[toolName].renderResult;

  if (!renderResult) {
    return new Text("", 0, 0);
  }

  return renderResult(result, options, theme, context);
}

// =========================================================================
// Read Tool
// =========================================================================

const MAX_DISPLAY_LINES = 30;

export function renderReadResult(
  result: any,
  options: ToolRenderResultOptions,
  theme: any,
  _context: any,
): Component {
  if (!options.expanded) return new Text("", 0, 0);

  const imageContent = result.content?.find((c: any) => c.type === "image");
  if (imageContent) {
    const label =
      result.content?.find((c: any) => c.type === "text")?.text ?? "image";
    const sizeKb = Math.round((imageContent.data.length * 0.75) / 1024);

    return new Text(
      theme.fg(
        "toolOutput",
        `${label} [${imageContent.mimeType}, ${sizeKb}KB]`,
      ),
      0,
      0,
    );
  }

  const textContent = result.content?.find((c: any) => c.type === "text");
  if (!textContent) return new Text("", 0, 0);

  const lines = textContent.text.split("\n");
  const truncated = lines.length > MAX_DISPLAY_LINES;
  const displayLines = truncated ? lines.slice(0, MAX_DISPLAY_LINES) : lines;

  let text = displayLines
    .map((line: string) => theme.fg("toolOutput", line))
    .join("\n");
  if (truncated) {
    text += `\n${theme.fg("muted", `... (${lines.length - MAX_DISPLAY_LINES} more lines hidden)`)}`;
  }

  return new Text(text, 0, 0);
}

// =========================================================================
// Write Tool
// =========================================================================

export function renderWriteResult(
  result: any,
  options: ToolRenderResultOptions,
  theme: any,
  context: any,
): Component {
  if (!options.expanded) return new Text("", 0, 0);

  return renderBuiltInResult("write", result, options, theme, context);
}

// =========================================================================
// Edit Tool
// =========================================================================

export function renderEditResult(
  result: any,
  options: ToolRenderResultOptions,
  theme: any,
  _context: any,
): Component {
  const details = result.details as EditToolDetails | undefined;
  const content = result.content[0];

  if (content?.type === "text" && content.text.startsWith("Error")) {
    return new Text(theme.fg("error", content.text.split("\n")[0]), 0, 0);
  }

  if (!details?.diff) {
    return new Text(theme.fg("success", "Applied"), 0, 0);
  }

  let additions = 0;
  let removals = 0;
  for (const line of details.diff.split("\n")) {
    if (line.startsWith("+") && !line.startsWith("+++")) additions++;
    if (line.startsWith("-") && !line.startsWith("---")) removals++;
  }

  const summary =
    theme.fg("success", ` +${additions}`) +
    theme.fg("dim", "/") +
    theme.fg("error", `-${removals}`);

  if (!options.expanded) return new Text(summary, 0, 0);
  return new Text(`${summary}\n${renderDiff(details.diff)}`, 0, 0);
}

// =========================================================================
// Find Tool
// =========================================================================

export function renderFindResult(
  result: any,
  options: ToolRenderResultOptions,
  theme: any,
  context: any,
): Component {
  if (!options.expanded) return renderCollapsedCount(result, theme, "files");

  return renderBuiltInResult("find", result, options, theme, context);
}

// =========================================================================
// Grep Tool
// =========================================================================

export function renderGrepResult(
  result: any,
  options: ToolRenderResultOptions,
  theme: any,
  context: any,
): Component {
  if (!options.expanded) {
    return renderCollapsedCount(result, theme, "matches");
  }

  return renderBuiltInResult("grep", result, options, theme, context);
}

// =========================================================================
// Bash Tool
// =========================================================================

export function renderBashResult(
  result: any,
  options: ToolRenderResultOptions,
  theme: any,
  context: any,
): Component {
  if (!options.expanded) return new Text("", 0, 0);

  return renderBuiltInResult("bash", result, options, theme, context);
}

// =========================================================================
// Ls Tool
// =========================================================================

export function renderLsResult(
  result: any,
  options: ToolRenderResultOptions,
  theme: any,
  context: any,
): Component {
  if (!options.expanded) return renderCollapsedCount(result, theme, "entries");

  return renderBuiltInResult("ls", result, options, theme, context);
}
