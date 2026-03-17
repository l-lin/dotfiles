import type { TavilyResponse } from "./types.js";

export function formatResultsAsMarkdown(
  data: TavilyResponse,
  includeRawContent: boolean,
): string {
  const parts: string[] = [`# Search Results: ${data.query}`];

  if (data.answer) {
    parts.push("## AI Summary", "", data.answer, "", "---");
  }

  const results = data.results || [];
  parts.push(`## Results (${results.length})`, "");

  if (results.length === 0) {
    parts.push("*No results found.*");
  } else {
    results.forEach((result, index) => {
      const title = `### ${index + 1}. ${result.title || "Untitled"}`;
      const url = `**URL:** ${result.url}`;
      const score = `**Relevance Score:** ${(result.score * 100).toFixed(1)}%`;
      const excerpt = result.content || "No content available";

      parts.push(title, "", url, score, "", "**Excerpt:**", "", excerpt, "");

      if (includeRawContent && result.raw_content) {
        const truncated = result.raw_content.slice(0, 1000);
        const suffix =
          result.raw_content.length > 1000 ? "\n...(truncated)" : "";
        parts.push(
          "<details>",
          "<summary>Raw Content</summary>",
          "",
          "```",
          truncated + suffix,
          "```",
          "",
          "</details>",
          "",
        );
      }

      parts.push("---", "");
    });
  }

  parts.push(`*Search completed in ${(data.response_time || 0).toFixed(2)}s*`);

  return parts.join("\n");
}
