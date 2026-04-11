import assert from "node:assert/strict";
import test from "node:test";
import { addSkillToRange, buildRangeAgg } from "./aggregation.js";
import { renderBreakdownBody, renderSkillTable } from "./renderer.js";
import type { SkillBreakdownData } from "./types.js";

function given_data(now: Date) {
  const range = buildRangeAgg(30, now);
  addSkillToRange(
    range,
    "skill-alpha",
    new Date("2026-04-10T08:00:00.000Z"),
    null,
    null,
  );
  addSkillToRange(
    range,
    "skill-alpha",
    new Date("2026-04-10T08:01:00.000Z"),
    null,
    null,
  );
  addSkillToRange(
    range,
    "skill-beta",
    new Date("2026-04-10T09:00:00.000Z"),
    null,
    null,
  );
  addSkillToRange(
    range,
    "skill-gamma",
    new Date("2026-04-10T10:00:00.000Z"),
    null,
    null,
  );

  const data: SkillBreakdownData = {
    generatedAt: now,
    ranges: new Map([[30, range]]),
    palette: {
      skillColors: new Map([
        ["skill-alpha", { r: 64, g: 196, b: 99 }],
        ["skill-beta", { r: 47, g: 129, b: 247 }],
        ["skill-gamma", { r: 163, g: 113, b: 247 }],
      ]),
      orderedSkills: ["skill-alpha", "skill-beta", "skill-gamma"],
      otherColor: { r: 160, g: 160, b: 160 },
    },
  };

  return { range, data };
}

test("renderSkillTable GIVEN more than ten skills WHEN rendering THEN it keeps ten data rows", () => {
  const now = new Date("2026-04-11T12:00:00.000Z");
  const range = buildRangeAgg(30, now);

  for (let index = 0; index < 11; index++) {
    addSkillToRange(
      range,
      `skill-${index}`,
      new Date(`2026-04-${String(index + 1).padStart(2, "0")}T08:00:00.000Z`),
      null,
      null,
    );
  }

  const actual = renderSkillTable(range);
  const renderedRows = actual.filter((line) => line.startsWith("skill-"));

  assert.equal(renderedRows.length, 10);
});

test("renderBreakdownBody GIVEN search mode and a selected match index WHEN rendering THEN only the selected fuzzy result is highlighted", () => {
  const now = new Date("2026-04-11T12:00:00.000Z");
  const { range, data } = given_data(now);

  const actual = (renderBreakdownBody as any)(
    range,
    30,
    data,
    false,
    120,
    1,
    "skills",
    null,
    null,
    true,
    "skill",
    1,
  ).join("\n");
  const plainText = actual.replace(/\x1B\[[0-9;]*m/g, "");

  assert.match(plainText, /> skill-alpha/i);
  assert.doesNotMatch(plainText, /> skill-beta/i);
});
