export interface TipRule {
  match: RegExp;
  tip: string;
}

export const TIP_RULES: readonly TipRule[] = [
  {
    match: /\bplan\b/i,
    tip: "󰌵 run /skill:devils-advocate or /replan or /visual-explainer",
  },
  {
    match: /\bimplement\b/i,
    tip: "󰌵 run /self-review or /code-reviewer or /judge-code",
  },
  {
    match: /\bcommit\b/i,
    tip: "󰌵 run /gh-pr",
  },
  {
    match: /\bhandoff\b/i,
    tip: "󰌵 run /pickup",
  },
] as const;

export function findRuleForInput(input: string): TipRule | undefined {
  return TIP_RULES.find((rule) => rule.match.test(input));
}
