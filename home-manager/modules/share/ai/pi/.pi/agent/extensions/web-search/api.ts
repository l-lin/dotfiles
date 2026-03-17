import type { TavilyResponse } from "./types.js";

export async function searchTavily(
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
