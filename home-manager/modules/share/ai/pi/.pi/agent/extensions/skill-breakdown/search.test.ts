import assert from "node:assert/strict";
import test from "node:test";
import { findSkillMatches } from "./search.js";
import type { SkillRangeAgg } from "./types.js";

function given_range(skillCounts: Array<[string, number]>): SkillRangeAgg {
  const totalInvocations = skillCounts.reduce(
    (sum, [, count]) => sum + count,
    0,
  );

  return {
    days: [],
    dayByKey: new Map(),
    totalInvocations,
    sessionCount: 0,
    skillCounts: new Map(skillCounts),
    projectCountsBySkill: new Map(),
    modelCountsBySkill: new Map(),
    projectModelCountsBySkill: new Map(),
  };
}

test("findSkillMatches GIVEN a numeric query WHEN matching THEN it searches both skill names and rendered numbers", () => {
  const range = given_range([
    ["skill-alpha", 3],
    ["skill-beta", 12],
    ["skill-gamma", 1],
  ]);

  const actual = findSkillMatches(range, "12");

  assert.equal(actual[0]?.skillName, "skill-beta");
  assert.match(actual[0]?.label ?? "", /12/);
});
