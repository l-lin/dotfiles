import assert from "node:assert/strict";
import test from "node:test";
import type { AssistantMessage } from "@mariozechner/pi-ai";
import {
  getAssistantErrorMessage,
  getRequestAuthOptions,
  normalizeReasoningLevel,
} from "./index.js";

const EMPTY_USAGE = {
  input: 0,
  output: 0,
  cacheRead: 0,
  cacheWrite: 0,
  totalTokens: 0,
  cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
};

function given_assistantErrorMessage(errorMessage?: string): AssistantMessage {
  return {
    role: "assistant",
    content: [],
    api: "openai-responses",
    provider: "openai",
    model: "gpt-4o",
    usage: EMPTY_USAGE,
    stopReason: "error",
    errorMessage,
    timestamp: 1,
  };
}

test("normalizeReasoningLevel GIVEN off WHEN normalizing THEN undefined is returned", () => {
  const actual = normalizeReasoningLevel("off");

  assert.equal(actual, undefined);
});

test("normalizeReasoningLevel GIVEN a supported thinking level WHEN normalizing THEN the same level is returned", () => {
  const actual = normalizeReasoningLevel("medium");
  const expected = "medium";

  assert.equal(actual, expected);
});

test("getRequestAuthOptions GIVEN headers-only auth WHEN building THEN headers are preserved", () => {
  const actual = getRequestAuthOptions({
    ok: true,
    headers: { authorization: "Bearer token" },
  });
  const expected = {
    apiKey: undefined,
    headers: { authorization: "Bearer token" },
  };

  assert.deepEqual(actual, expected);
});

test("getRequestAuthOptions GIVEN a failed auth resolution WHEN building THEN it throws the registry error", () => {
  assert.throws(
    () => getRequestAuthOptions({ ok: false, error: "No auth configured" }),
    /No auth configured/,
  );
});

test("getAssistantErrorMessage GIVEN a provider error message WHEN extracting THEN it returns that message", () => {
  const actual = getAssistantErrorMessage(
    given_assistantErrorMessage("Rate limited"),
  );
  const expected = "Rate limited";

  assert.equal(actual, expected);
});

test("getAssistantErrorMessage GIVEN no provider error message WHEN extracting THEN it falls back to a generic message", () => {
  const actual = getAssistantErrorMessage(given_assistantErrorMessage());
  const expected = "Request failed";

  assert.equal(actual, expected);
});
