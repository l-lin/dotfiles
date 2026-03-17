import { Type } from "@sinclair/typebox";

export const DEFAULT_MAX_LENGTH = 50_000;
export const FETCH_TIMEOUT_MS = 30_000;

export const WebFetchParams = Type.Object({
  url: Type.String({
    description: "URL to fetch (must include scheme, e.g. https://example.com)",
  }),
  mode: Type.Optional(
    Type.Union([Type.Literal("raw"), Type.Literal("readable")], {
      description:
        '"raw" returns the full HTML/text body; "readable" strips tags and extracts human-readable text (default: "readable")',
    }),
  ),
  max_length: Type.Optional(
    Type.Number({
      description: `Maximum number of characters to return (default: ${DEFAULT_MAX_LENGTH})`,
      minimum: 100,
      maximum: 500_000,
    }),
  ),
});

export interface FetchDetails {
  url: string;
  mode: "raw" | "readable";
  status: number;
  contentType: string;
  originalLength: number;
  returnedLength: number;
  truncated: boolean;
  error?: string;
}
