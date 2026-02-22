/**
 * Web Search Extension - Internet search via Tavily API
 *
 * Provides a tool for searching the web using Tavily's search API.
 * Supports both basic and advanced search options with markdown-formatted results.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";

// ============================================================================
// Types
// ============================================================================

interface TavilySearchResult {
  title: string;
  url: string;
  content: string;
  score: number;
  raw_content?: string;
}

interface TavilyResponse {
  query: string;
  results: TavilySearchResult[];
  answer?: string;
  images?: string[];
  response_time: number;
}

// ============================================================================
// Schema
// ============================================================================

const WebSearchParams = Type.Object({
  query: Type.String({
    description: "Search query string",
  }),
  search_depth: Type.Optional(
    Type.Union([Type.Literal("basic"), Type.Literal("advanced")], {
      description:
        'Search depth: "basic" for quick results, "advanced" for comprehensive search (default: basic)',
    }),
  ),
  max_results: Type.Optional(
    Type.Number({
      description: "Maximum number of results to return (default: 5, max: 20)",
      minimum: 1,
      maximum: 20,
    }),
  ),
  include_domains: Type.Optional(
    Type.Array(Type.String(), {
      description:
        "List of domains to specifically include in search (e.g., ['github.com', 'stackoverflow.com'])",
    }),
  ),
  exclude_domains: Type.Optional(
    Type.Array(Type.String(), {
      description:
        "List of domains to exclude from search (e.g., ['pinterest.com'])",
    }),
  ),
  include_answer: Type.Optional(
    Type.Boolean({
      description:
        "Include AI-generated answer summary from search results (default: false)",
    }),
  ),
  include_raw_content: Type.Optional(
    Type.Boolean({
      description: "Include raw HTML content in results (default: false)",
    }),
  ),
});

// ============================================================================
// Tavily API
// ============================================================================

async function searchTavily(
  apiKey: string,
  params: {
    query: string;
    search_depth?: "basic" | "advanced";
    max_results?: number;
    include_domains?: string[];
    exclude_domains?: string[];
    include_answer?: boolean;
    include_raw_content?: boolean;
  },
): Promise<TavilyResponse> {
  const requestBody = {
    api_key: apiKey,
    query: params.query,
    search_depth: params.search_depth || "basic",
    max_results: Math.min(params.max_results || 5, 20),
    include_domains: params.include_domains || [],
    exclude_domains: params.exclude_domains || [],
    include_answer: params.include_answer || false,
    include_raw_content: params.include_raw_content || false,
  };

  const response = await fetch("https://api.tavily.com/search", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(
      `Tavily API error (${response.status}): ${errorText || response.statusText}`,
    );
  }

  return (await response.json()) as TavilyResponse;
}

// ============================================================================
// Formatting
// ============================================================================

function formatResultsAsMarkdown(
  data: TavilyResponse,
  includeRawContent: boolean,
): string {
  const lines: string[] = [];

  lines.push(`# Search Results: ${data.query || "Unknown"}`);
  lines.push("");

  if (data.answer) {
    lines.push("## AI Summary");
    lines.push("");
    lines.push(data.answer);
    lines.push("");
    lines.push("---");
    lines.push("");
  }

  const results = data.results || [];
  lines.push(`## Results (${results.length})`);
  lines.push("");

  if (results.length === 0) {
    lines.push("*No results found.*");
    lines.push("");
  }

  results.forEach((result, index) => {
    lines.push(`### ${index + 1}. ${result.title || "Untitled"}`);
    lines.push("");
    lines.push(`**URL:** ${result.url || "N/A"}`);
    lines.push(`**Relevance Score:** ${((result.score || 0) * 100).toFixed(1)}%`);
    lines.push("");
    lines.push("**Excerpt:**");
    lines.push("");
    lines.push(result.content || "No content available");
    lines.push("");

    if (includeRawContent && result.raw_content) {
      lines.push("<details>");
      lines.push("<summary>Raw Content</summary>");
      lines.push("");
      lines.push("```");
      lines.push(result.raw_content.slice(0, 1000)); // Limit raw content to 1000 chars
      if (result.raw_content.length > 1000) {
        lines.push("...(truncated)");
      }
      lines.push("```");
      lines.push("");
      lines.push("</details>");
      lines.push("");
    }

    lines.push("---");
    lines.push("");
  });

  lines.push(
    `*Search completed in ${(data.response_time || 0).toFixed(2)}s*`,
  );

  return lines.join("\n");
}

// ============================================================================
// Extension
// ============================================================================

export default function webSearchExtension(pi: ExtensionAPI) {
  pi.registerTool({
    name: "web-search",
    label: "Web Search",
    description:
      "Search the internet using Tavily API. Supports basic and advanced search with domain filtering and AI-generated summaries.",
    parameters: WebSearchParams,

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      // Check for API key
      const apiKey = process.env.TAVILY_API_KEY;
      if (!apiKey) {
        return {
          content: [
            {
              type: "text",
              text: "Error: TAVILY_API_KEY environment variable is not set. Please configure your Tavily API key.",
            },
          ],
          isError: true,
        };
      }

      // Validate query
      if (!params.query || params.query.trim() === "") {
        return {
          content: [
            {
              type: "text",
              text: "Error: Search query cannot be empty.",
            },
          ],
          isError: true,
        };
      }

      try {
        const results = await searchTavily(apiKey, params);
        
        // Validate response structure
        if (!results || typeof results !== "object") {
          return {
            content: [
              {
                type: "text",
                text: "Error: Invalid response from Tavily API.",
              },
            ],
            isError: true,
          };
        }

        const markdown = formatResultsAsMarkdown(
          results,
          params.include_raw_content || false,
        );

        return {
          content: [{ type: "text", text: markdown }],
          details: {
            query: params.query,
            resultCount: (results.results || []).length,
            hasAnswer: !!results.answer,
            responseTime: results.response_time || 0,
          },
        };
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        return {
          content: [
            {
              type: "text",
              text: `Web search failed: ${errorMessage}`,
            },
          ],
          isError: true,
        };
      }
    },

    renderCall(args, theme) {
      const query = (args.query as string) || "(empty)";
      const depth = (args.search_depth as string) || "basic";
      const maxResults = (args.max_results as number) || 5;

      let text = theme.fg("toolTitle", theme.bold("Web Search "));
      text += theme.fg("accent", `"${query}"`);
      text += theme.fg(
        "dim",
        ` (${depth}, max ${maxResults} results)`,
      );

      return new Text(text, 0, 0);
    },

    renderResult(result, opts, theme) {
      if (result.isError) {
        const errorText =
          result.content[0]?.type === "text" ? result.content[0].text : "";
        return new Text(theme.fg("error", errorText), 0, 0);
      }

      // When expanded, show full markdown results
      if (opts.expanded && result.content[0]?.type === "text") {
        return new Text(result.content[0].text, 0, 0);
      }

      // When collapsed, show summary
      const details = result.details as
        | {
            query: string;
            resultCount: number;
            hasAnswer: boolean;
            responseTime: number;
          }
        | undefined;

      if (!details) {
        return new Text(
          theme.fg("success", "Search completed"),
          0,
          0,
        );
      }

      let text = theme.fg("success", "✓ ");
      text += theme.fg("text", `Found ${details.resultCount} results`);

      if (details.hasAnswer) {
        text += theme.fg("muted", " (with AI summary)");
      }

      text += theme.fg(
        "dim",
        ` • ${details.responseTime.toFixed(2)}s`,
      );

      return new Text(text, 0, 0);
    },
  });
}
