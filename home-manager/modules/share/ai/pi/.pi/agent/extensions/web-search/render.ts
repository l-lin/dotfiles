import type {
  AgentToolResult,
  Theme,
  ToolRenderResultOptions,
} from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import type { WebSearchDetails } from "./types.js";

export function renderCall(args: any, theme: Theme): Text {
  const query = args.query || "(empty)";
  const depth = args.search_depth || "basic";
  const maxResults = args.max_results || 5;

  const title = theme.fg("toolTitle", theme.bold("Web Search "));
  const queryText = theme.fg("accent", `"${query}"`);
  const details = theme.fg("dim", ` (${depth}, max ${maxResults} results)`);

  return new Text(title + queryText + details, 0, 0);
}

export function renderResult(
  result: AgentToolResult<WebSearchDetails>,
  opts: ToolRenderResultOptions,
  theme: Theme,
): Text {
  const details = result.details as WebSearchDetails | undefined;

  if (details?.error) {
    const text =
      result.content[0]?.type === "text"
        ? result.content[0].text
        : details.error;
    return new Text(theme.fg("error", text), 0, 0);
  }

  if (opts.expanded && result.content[0]?.type === "text") {
    return new Text(result.content[0].text, 0, 0);
  }

  if (!details) {
    return new Text(theme.fg("success", "Search completed"), 0, 0);
  }

  const check = theme.fg("success", "✓ ");
  const count = theme.fg("text", `Found ${details.resultCount} results`);
  const summary = details.hasAnswer
    ? theme.fg("muted", " (with AI summary)")
    : "";
  const time = theme.fg("dim", ` • ${details.responseTime.toFixed(2)}s`);

  return new Text(check + count + summary + time, 0, 0);
}
