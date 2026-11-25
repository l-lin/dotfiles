import assert from "node:assert/strict";
import test from "node:test";
import type {
  ExtensionToolContext,
  ToolDefinition,
} from "@earendil-works/pi-coding-agent";
import askUserQuestion from "./index.js";
import type { QuestionnaireParams, Result } from "./types.js";

function given_tool() {
  let tool: ToolDefinition<typeof QuestionnaireParams, Result> | undefined;
  askUserQuestion({
    registerCommand() {},
    registerTool(definition: typeof tool) {
      tool = definition;
    },
    on() {},
  } as never);
  assert.ok(tool);
  return tool;
}

const blocked = {
  blocked: { kind: "question", message: "Waiting for your answer" },
};

for (const { location, session, block, mode, expected } of [
  {
    location: "a Rex terminal",
    session: "session:test",
    block: "block:test",
    mode: "tui",
    expected: blocked,
  },
  { location: "a terminal outside Rex", mode: "tui", expected: undefined },
  {
    location: "a terminal with only a Rex session",
    session: "session:test",
    mode: "tui",
    expected: undefined,
  },
  {
    location: "a terminal with only a Rex block",
    block: "block:test",
    mode: "tui",
    expected: undefined,
  },
  {
    location: "Rex with Pi in RPC mode",
    session: "session:test",
    block: "block:test",
    mode: "rpc",
    expected: undefined,
  },
]) {
  test(`GIVEN ${location} WHEN the tool opens a question THEN it sets blocked status only in a Rex TUI`, async (t) => {
    for (const [key, value] of [
      ["REX_SESSION", session],
      ["REX_BLOCK", block],
    ] as const) {
      const previous = process.env[key];
      t.after(() => {
        if (previous === undefined) delete process.env[key];
        else process.env[key] = previous;
      });
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }

    const custom = t.mock.fn(
      async (_factory: unknown, _options: unknown): Promise<Result> => ({
        questions: [],
        answers: [],
        cancelled: true,
      }),
    );
    const ctx = {
      hasUI: true,
      mode,
      ui: { custom },
    } as unknown as ExtensionToolContext;
    await given_tool().execute(
      "call-1",
      { questions: [{ id: "scope", prompt: "Which scope?", options: [] }] },
      undefined,
      undefined,
      ctx,
    );

    assert.equal(custom.mock.callCount(), 1);
    const actual = custom.mock.calls[0].arguments[1];
    assert.deepEqual(actual, expected);
  });
}
