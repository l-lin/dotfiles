export interface TipRule {
  match: RegExp;
  tip: string;
}

export const TIP_RULES: readonly TipRule[] = [
  {
    match: /\bplan\b/i,
    tip: "run /skill:devils-advocate or /skill:explain-visually",
  },
  {
    match: /\bimplement\b/i,
    tip: "run /skill:self-review or /skill:review-code",
  },
  {
    match: /\bcommit\b/i,
    tip: "run /skill:create-gh-pr",
  },
] as const;

export function findRuleForInput(input: string): TipRule | undefined {
  return TIP_RULES.find((rule) => rule.match.test(input));
}
