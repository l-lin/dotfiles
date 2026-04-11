import assert from "node:assert/strict";
import test from "node:test";
import {
  getOrderedModelsForSkill,
  getProjectCountsForSkill,
} from "./aggregation.js";
import {
  given_readAssistantMessage,
  given_readToolResultMessage,
  given_sessionFile,
  given_sessionStartEntry,
  given_tempDirectory,
  when_computingBreakdown,
} from "./test-helpers.js";

test("computeSkillBreakdown GIVEN skill loads across projects and models WHEN aggregating THEN it exposes project totals and model ordering for the selected skill", async (t) => {
  const tempDirectory = given_tempDirectory(t);
  const now = new Date("2026-04-11T12:00:00.000Z");

  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-09T08-00-00-000Z_project-a-alpha.jsonl",
    entries: [
      given_sessionStartEntry("2026-04-09T08:00:00.000Z", "/work/project-a"),
      given_readAssistantMessage("2026-04-09T08:00:01.000Z", [
        { id: "call-a-alpha", skillName: "jira", model: "model-alpha" },
      ]),
      given_readToolResultMessage({
        timestamp: "2026-04-09T08:00:02.000Z",
        toolCallId: "call-a-alpha",
      }),
    ],
  });
  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-09T09-00-00-000Z_project-a-beta.jsonl",
    entries: [
      given_sessionStartEntry("2026-04-09T09:00:00.000Z", "/work/project-a"),
      given_readAssistantMessage("2026-04-09T09:00:01.000Z", [
        { id: "call-a-beta", skillName: "jira", model: "model-beta" },
      ]),
      given_readToolResultMessage({
        timestamp: "2026-04-09T09:00:02.000Z",
        toolCallId: "call-a-beta",
      }),
    ],
  });
  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-09T10-00-00-000Z_project-b-alpha.jsonl",
    entries: [
      given_sessionStartEntry("2026-04-09T10:00:00.000Z", "/work/project-b"),
      given_readAssistantMessage("2026-04-09T10:00:01.000Z", [
        { id: "call-b-alpha", skillName: "jira", model: "model-alpha" },
      ]),
      given_readToolResultMessage({
        timestamp: "2026-04-09T10:00:02.000Z",
        toolCallId: "call-b-alpha",
      }),
    ],
  });

  const actual = await when_computingBreakdown(tempDirectory, now);
  const range = actual.ranges.get(30)!;

  const actualProjects = getProjectCountsForSkill(range, "jira");
  const actualModels = getOrderedModelsForSkill(range, "jira");

  assert.deepEqual(
    actualProjects,
    new Map([
      ["/work/project-a", 2],
      ["/work/project-b", 1],
    ]),
  );
  assert.deepEqual(actualModels, ["test/model-alpha", "test/model-beta"]);
});
