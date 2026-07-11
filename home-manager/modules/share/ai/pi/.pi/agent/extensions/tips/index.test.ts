import assert from "node:assert/strict";
import test from "node:test";

import tipsExtension from "./index.js";

const DIM_START = "\x1b[2m";
const DIM_END = "\x1b[0m";

function dim(text: string): string {
  return `${DIM_START}${text}${DIM_END}`;
}

type ExtensionHandler = (event: unknown, ctx: unknown) => unknown;

function given_mockPi() {
  const extensionHandlers = new Map<string, ExtensionHandler[]>();

  return {
    pi: {
      on(event: string, handler: ExtensionHandler) {
        const handlers = extensionHandlers.get(event) ?? [];
        handlers.push(handler);
        extensionHandlers.set(event, handlers);
      },
    },
    async when_emittingExtensionEvent(
      event: string,
      payload: unknown,
      ctx: unknown,
    ) {
      for (const handler of extensionHandlers.get(event) ?? []) {
        await handler(payload, ctx);
      }
    },
  };
}

function given_statusContext() {
  const setStatusCalls: { key: string; text: string | undefined }[] = [];

  return {
    ctx: {
      hasUI: true,
      ui: {
        setStatus(key: string, text: string | undefined) {
          setStatusCalls.push({ key, text });
        },
      },
    },
    when_gettingLatestStatus() {
      return setStatusCalls.at(-1);
    },
    when_gettingAllStatusCalls() {
      return setStatusCalls;
    },
  };
}

test("tips GIVEN a /plan user message WHEN input fires THEN shows the devils-advocate tip", async () => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_gettingLatestStatus } = given_statusContext();

  tipsExtension(pi as never);

  await when_emittingExtensionEvent(
    "input",
    { type: "input", text: "/plan the implementation", source: "interactive" },
    ctx,
  );

  const actual = when_gettingLatestStatus();
  assert.equal(actual?.key, "tips");
  assert.match(actual?.text ?? "", /devils-advocate/);
});

test("tips GIVEN a /plan user message WHEN input fires THEN shows the devils-advocate or visual-explainer tip", async () => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_gettingLatestStatus } = given_statusContext();

  tipsExtension(pi as never);

  await when_emittingExtensionEvent(
    "input",
    {
      type: "input",
      text: "/plan with new constraints",
      source: "interactive",
    },
    ctx,
  );

  const actual = when_gettingLatestStatus();
  assert.equal(actual?.key, "tips");
  assert.match(actual?.text ?? "", /devils-advocate|visual-explainer/);
});

test("tips GIVEN an /implement user message WHEN input fires THEN shows the self-review tip", async () => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_gettingLatestStatus } = given_statusContext();

  tipsExtension(pi as never);

  await when_emittingExtensionEvent(
    "input",
    { type: "input", text: "/implement the feature", source: "interactive" },
    ctx,
  );

  const actual = when_gettingLatestStatus();
  assert.equal(actual?.key, "tips");
  assert.match(actual?.text ?? "", /self-review|code-reviewer|judge-code/);
});

test("tips GIVEN a /commit user message WHEN input fires THEN shows the gh-pr tip", async () => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_gettingLatestStatus } = given_statusContext();

  tipsExtension(pi as never);

  await when_emittingExtensionEvent(
    "input",
    {
      type: "input",
      text: "/commit -m 'fix: something'",
      source: "interactive",
    },
    ctx,
  );

  const actual = when_gettingLatestStatus();
  assert.equal(actual?.key, "tips");
  assert.match(actual?.text ?? "", /gh-pr/);
});

test("tips GIVEN a /handoff user message WHEN input fires THEN shows the pickup tip", async () => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_gettingLatestStatus } = given_statusContext();

  tipsExtension(pi as never);

  await when_emittingExtensionEvent(
    "input",
    { type: "input", text: "/handoff to next agent", source: "interactive" },
    ctx,
  );

  const actual = when_gettingLatestStatus();
  assert.equal(actual?.key, "tips");
  assert.match(actual?.text ?? "", /pickup/);
});

test("tips GIVEN a non-matching user message WHEN input fires THEN the previous tip persists", async () => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_gettingAllStatusCalls } = given_statusContext();

  tipsExtension(pi as never);

  // Set a tip with /plan
  await when_emittingExtensionEvent(
    "input",
    { type: "input", text: "/plan something", source: "interactive" },
    ctx,
  );

  // Then send a non-matching message
  await when_emittingExtensionEvent(
    "input",
    { type: "input", text: "Just some regular text", source: "interactive" },
    ctx,
  );

  const calls = when_gettingAllStatusCalls();
  const lastCall = calls.at(-1);
  assert.equal(lastCall?.key, "tips");
  assert.match(lastCall?.text ?? "", /devils-advocate/);
});

test("tips GIVEN a session_start event WHEN fired THEN clears the tip", async () => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_gettingAllStatusCalls } = given_statusContext();

  tipsExtension(pi as never);

  // Set a tip first
  await when_emittingExtensionEvent(
    "input",
    { type: "input", text: "/plan something", source: "interactive" },
    ctx,
  );

  // Then fire session_start
  await when_emittingExtensionEvent(
    "session_start",
    { type: "session_start" },
    ctx,
  );

  const calls = when_gettingAllStatusCalls();
  const lastCall = calls.at(-1);
  assert.equal(lastCall?.key, "tips");
  assert.equal(lastCall?.text, undefined);
});

test("tips GIVEN a /plan command with trailing args WHEN input fires THEN matches the rule", async () => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_gettingLatestStatus } = given_statusContext();

  tipsExtension(pi as never);

  await when_emittingExtensionEvent(
    "input",
    {
      type: "input",
      text: "/plan with detailed specs for the new feature",
      source: "interactive",
    },
    ctx,
  );

  const actual = when_gettingLatestStatus();
  assert.equal(actual?.key, "tips");
  assert.match(actual?.text ?? "", /devils-advocate/);
});

test("tips GIVEN a message without any matched keyword WHEN input fires THEN does not set the tip", async () => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_gettingLatestStatus } = given_statusContext();

  tipsExtension(pi as never);

  await when_emittingExtensionEvent(
    "input",
    {
      type: "input",
      text: "I'll build this feature for you.",
      source: "interactive",
    },
    ctx,
  );

  const actual = when_gettingLatestStatus();
  assert.equal(actual, undefined);
});

test("tips GIVEN a case-insensitive PLAN command WHEN input fires THEN matches the rule", async () => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_gettingLatestStatus } = given_statusContext();

  tipsExtension(pi as never);

  await when_emittingExtensionEvent(
    "input",
    {
      type: "input",
      text: "PLAN the implementation",
      source: "interactive",
    },
    ctx,
  );

  const actual = when_gettingLatestStatus();
  assert.equal(actual?.key, "tips");
  assert.match(actual?.text ?? "", /devils-advocate/);
});

test("tips GIVEN a /plan command embedded in full prompt WHEN input fires THEN matches the whole input", async () => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_gettingLatestStatus } = given_statusContext();

  tipsExtension(pi as never);

  // pi transforms prompt templates into full prompts, so the input is
  // the whole prompt, not just /plan.
  await when_emittingExtensionEvent(
    "input",
    {
      type: "input",
      text: "Please /plan the implementation of the new auth module",
      source: "interactive",
    },
    ctx,
  );

  const actual = when_gettingLatestStatus();
  assert.equal(actual?.key, "tips");
  assert.match(actual?.text ?? "", /devils-advocate/);
});

test("tips GIVEN implement embedded in sentence WHEN input fires THEN does not match (not whole word)", async () => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_gettingLatestStatus } = given_statusContext();

  tipsExtension(pi as never);

  // "implementation" contains "implement" but is not the whole word.
  await when_emittingExtensionEvent(
    "input",
    {
      type: "input",
      text: "Write the implementation file",
      source: "interactive",
    },
    ctx,
  );

  const actual = when_gettingLatestStatus();
  assert.equal(actual, undefined);
});
