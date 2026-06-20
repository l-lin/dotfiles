export const TOKEN_METRIC_CHANGED_EVENT = "token-metric:changed";

export interface TokenMetricSnapshot {
  tps: number | null;
}

export const EMPTY_TOKEN_METRIC_SNAPSHOT: TokenMetricSnapshot = {
  tps: null,
};

export function isTokenMetricSnapshot(
  value: unknown,
): value is TokenMetricSnapshot {
  if (typeof value !== "object" || value === null) return false;

  const candidate = value as Record<string, unknown>;
  return candidate.tps === null || typeof candidate.tps === "number";
}
