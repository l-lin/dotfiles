import { formatCount } from "../session-breakdown/color-utils.js";
import { formatShare, sortMapByValueDesc } from "./aggregation.js";
import { SEARCH_MATCH_LIMIT } from "./constants.js";
import type { SkillRangeAgg, SkillName } from "./types.js";

export interface SkillSearchMatch {
  skillName: SkillName;
  count: number;
  share: string;
  label: string;
  score: number;
}

function fuzzyScore(query: string, text: string): number {
  const normalizedQuery = query.trim().toLowerCase();
  const normalizedText = text.toLowerCase();
  if (!normalizedQuery) return 0;

  const directIndex = normalizedText.indexOf(normalizedQuery);
  if (directIndex !== -1) {
    return 10_000 - directIndex - normalizedText.length;
  }

  let lastIndex = -1;
  let score = 0;
  for (const character of normalizedQuery) {
    const nextIndex = normalizedText.indexOf(character, lastIndex + 1);
    if (nextIndex === -1) return -1;

    score += 8;
    if (nextIndex === lastIndex + 1) score += 6;
    if (
      nextIndex === 0 ||
      " /_-:(".includes(normalizedText[nextIndex - 1] ?? "")
    ) {
      score += 4;
    }
    score -= Math.max(0, nextIndex - lastIndex - 1);
    lastIndex = nextIndex;
  }

  return score - normalizedText.length;
}

export function findSkillMatches(
  range: SkillRangeAgg,
  query: string,
  limit = SEARCH_MATCH_LIMIT,
): SkillSearchMatch[] {
  const normalizedQuery = query.trim();
  const rows = sortMapByValueDesc(range.skillCounts);

  return rows
    .map((row) => {
      const share = formatShare(row.value, range.totalInvocations);
      const label = `${row.key} · ${formatCount(row.value)} · ${share}`;
      const score = normalizedQuery ? fuzzyScore(normalizedQuery, label) : 0;
      return {
        skillName: row.key,
        count: row.value,
        share,
        label,
        score,
      };
    })
    .filter((match) => normalizedQuery.length === 0 || match.score >= 0)
    .sort((left, right) => {
      if (right.score !== left.score) return right.score - left.score;
      if (right.count !== left.count) return right.count - left.count;
      return left.skillName.localeCompare(right.skillName);
    })
    .slice(0, limit);
}
