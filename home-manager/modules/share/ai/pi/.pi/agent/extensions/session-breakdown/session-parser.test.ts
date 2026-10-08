import assert from "node:assert/strict";
import { mkdtemp, writeFile, rm, utimes } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test, { type TestContext } from "node:test";
import { addSessionToRange, buildRangeAgg } from "./aggregation.js";
import { parseSessionFile, walkSessionFiles } from "./session-parser.js";
import { toLocalDayKey } from "./date-utils.js";

async function given_sessionFile(t: TestContext, entries: unknown[]) {
  const directory = await mkdtemp(path.join(os.tmpdir(), "session-breakdown-"));
  t.after(() => rm(directory, { recursive: true, force: true }));
  const filePath = path.join(directory, "2026-01-01T10-00-00-000Z_demo.jsonl");
  await writeFile(
    filePath,
    entries.map((entry) => JSON.stringify(entry)).join("\n"),
  );
  return { directory, filePath };
}

function given_message(timestamp: Date, cost: number, model = "gpt-6-astra") {
  return {
    type: "message",
    timestamp: timestamp.toISOString(),
    message: {
      role: "assistant",
      provider: "test",
      model,
      usage: { totalTokens: 100, cost: { total: cost } },
    },
  };
}

test("GIVEN an old session resumed across days WHEN aggregating THEN usage follows activity dates and range sessions stay unique", async (t) => {
  const firstDay = new Date(2026, 9, 6, 23, 59);
  const secondDay = new Date(2026, 9, 7, 0, 1);
  const { filePath } = await given_sessionFile(t, [
    { type: "session", cwd: "/work/project" },
    given_message(new Date(2026, 0, 1, 12), 50, "old-model"),
    given_message(firstDay, 1),
    given_message(secondDay, 15),
    given_message(new Date(2026, 9, 7, 12), 2),
    given_message(new Date(2026, 9, 9, 12), 100),
  ]);
  const session = await parseSessionFile(filePath);
  assert.ok(session);

  const actual = buildRangeAgg(7, new Date(2026, 9, 8));
  addSessionToRange(actual, session);
  const expected = { cost: 18, tokens: 300, messages: 3, sessions: 1 };
  assert.equal(actual.totalCost, expected.cost);
  assert.equal(actual.totalTokens, expected.tokens);
  assert.equal(actual.totalMessages, expected.messages);
  assert.equal(actual.sessions, expected.sessions);
  assert.equal(actual.modelSessions.get("test/gpt-6-astra"), 1);
  assert.equal(actual.modelCost.has("test/old-model"), false);
  assert.equal(actual.cwdSessions.get("/work/project"), 1);
  assert.equal(actual.cwdCost.get("/work/project"), expected.cost);
  assert.equal(actual.dayByKey.get(toLocalDayKey(firstDay))?.totalCost, 1);
  assert.equal(actual.dayByKey.get(toLocalDayKey(secondDay))?.totalCost, 17);
  assert.equal(actual.dayByKey.get(toLocalDayKey(secondDay))?.sessions, 1);
  assert.equal(actual.dowCost.get("Wed"), 17);
  assert.equal(actual.todCost.get("after-midnight"), 15);

  const oneDay = buildRangeAgg(1, secondDay);
  addSessionToRange(oneDay, session);
  assert.equal(oneDay.totalCost, 17);
  assert.equal(oneDay.sessions, 1);
});

test("GIVEN standalone and nested usage WHEN parsing THEN all billed operations count without adding messages", async (t) => {
  const timestamp = new Date(2026, 9, 7, 12);
  const { filePath } = await given_sessionFile(t, [
    { type: "model_change", provider: "test", modelId: "gpt-6-astra" },
    given_message(timestamp, 1),
    {
      type: "usage",
      kind: "unknown-operation",
      timestamp: timestamp.toISOString(),
      provider: "other",
      modelId: "nested-model",
      usage: {
        input: 10,
        output: 20,
        cacheRead: 30,
        cacheWrite: 40,
        cost: { total: "2" },
      },
    },
    {
      type: "compaction",
      timestamp: timestamp.toISOString(),
      usage: { totalTokens: 200, cost: { total: 3 } },
    },
    {
      type: "branch_summary",
      timestamp: timestamp.toISOString(),
      usage: { totalTokens: 300, cost: 4 },
    },
    {
      type: "message",
      message: {
        role: "toolResult",
        timestamp: timestamp.getTime(),
        usage: { totalTokens: 400, cost: { total: 5 } },
      },
    },
    {
      type: "custom",
      timestamp: timestamp.toISOString(),
      usage: { totalTokens: 999, cost: 999 },
    },
  ]);
  const actual = await parseSessionFile(filePath);
  assert.ok(actual);
  const expected = { cost: 15, tokens: 1100, messages: 2 };
  assert.equal(actual.totalCost, expected.cost);
  assert.equal(actual.tokens, expected.tokens);
  assert.equal(actual.messages, expected.messages);
  assert.equal(actual.costByModel.get("other/nested-model"), 2);
  assert.equal(actual.costByModel.get("test/gpt-6-astra"), 13);
  const range = buildRangeAgg(1, timestamp);
  addSessionToRange(range, actual);
  assert.equal(range.totalCost, expected.cost);
  assert.equal(range.totalMessages, expected.messages);
});

test("GIVEN old filenames WHEN scanning THEN recently modified resumed sessions are included", async (t) => {
  const { directory, filePath } = await given_sessionFile(t, []);
  const cutoff = new Date(2026, 9, 1);
  const recent = new Date(2026, 9, 7);
  await utimes(filePath, recent, recent);
  const actual = await walkSessionFiles(directory, cutoff);
  const expected = [filePath];
  assert.deepEqual(actual, expected);
  const old = new Date(2026, 0, 1);
  await utimes(filePath, old, old);
  assert.deepEqual(await walkSessionFiles(directory, cutoff), []);
});

test("GIVEN legacy missing timestamps and an empty session WHEN parsing THEN creation-day fallback is preserved", async (t) => {
  const { filePath } = await given_sessionFile(t, [
    {
      type: "message",
      provider: "test",
      model: "legacy",
      usage: { promptTokens: 10, completionTokens: 5, cost: "1.5" },
    },
  ]);
  const actual = await parseSessionFile(filePath);
  assert.ok(actual);
  const expected = { tokens: 15, cost: 1.5 };
  const range = buildRangeAgg(1, actual.startedAt);
  addSessionToRange(range, actual);
  assert.equal(range.totalTokens, expected.tokens);
  assert.equal(range.totalCost, expected.cost);
  await writeFile(filePath, "");
  const emptySession = await parseSessionFile(filePath);
  assert.ok(emptySession);
  const emptyRange = buildRangeAgg(1, emptySession.startedAt);
  addSessionToRange(emptyRange, emptySession);
  assert.equal(emptyRange.sessions, 1);
  assert.equal(emptyRange.totalCost, 0);
});
