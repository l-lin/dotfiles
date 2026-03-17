import { Type } from "@sinclair/typebox";

export interface TavilySearchResult {
  title: string;
  url: string;
  content: string;
  score: number;
  raw_content?: string;
}

export interface TavilyResponse {
  query: string;
  results: TavilySearchResult[];
  answer?: string;
  images?: string[];
  response_time: number;
}

export interface WebSearchDetails {
  query: string;
  resultCount: number;
  hasAnswer: boolean;
  responseTime: number;
  error?: string;
}

export const WebSearchParams = Type.Object({
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
