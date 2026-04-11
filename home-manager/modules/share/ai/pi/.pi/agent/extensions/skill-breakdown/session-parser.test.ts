import assert from "node:assert/strict";
import test from "node:test";
import { parseSkillSessionFile } from "./session-parser.js";
import {
  given_readAssistantMessage,
  given_readToolResultMessage,
  given_sessionFile,
  given_sessionStartEntry,
  given_tempDirectory,
  then_expectParsedSession,
} from "./test-helpers.js";

test("parseSkillSessionFile GIVEN a successful read inside a project with a model WHEN parsing THEN it keeps the skill timestamp, project, and model", async (t) => {
  const tempDirectory = given_tempDirectory(t);
  const filePath = given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-10T08-00-00-000Z_demo.jsonl",
    entries: [
      given_sessionStartEntry("2026-04-10T08:00:00.000Z", "/work/project-a"),
      given_readAssistantMessage("2026-04-10T09:00:00.000Z", [
        { id: "call-jira", skillName: "jira", model: "model-alpha" },
      ]),
      given_readToolResultMessage({
        timestamp: "2026-04-10T09:00:01.000Z",
        toolCallId: "call-jira",
      }),
    ],
  });

  const actual = await parseSkillSessionFile(filePath);
  then_expectParsedSession(actual);

  assert.equal(
    actual.skillFirstLoadedAt.get("jira")?.toISOString(),
    "2026-04-10T09:00:01.000Z",
  );
  assert.equal(actual.skillProjectByName.get("jira"), "/work/project-a");
  assert.equal(actual.skillModelByName.get("jira"), "test/model-alpha");
});
