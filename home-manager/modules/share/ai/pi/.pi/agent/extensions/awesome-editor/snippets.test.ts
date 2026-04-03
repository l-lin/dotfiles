import assert from "node:assert/strict";
import test from "node:test";
import { withSnippets } from "./snippets.js";

function given_baseProviderExpectingOptions() {
  let receivedOptions: unknown;

  return {
    base: {
      getSuggestions(
        _lines: string[],
        _cursorLine: number,
        _cursorCol: number,
        options?: unknown,
      ) {
        receivedOptions = options;

        if (!options || typeof options !== "object") {
          throw new TypeError("Missing autocomplete options");
        }

        return {
          items: [{ value: "help", label: "help" }],
          prefix: "/",
        };
      },
      applyCompletion(
        lines: string[],
        cursorLine: number,
        cursorCol: number,
        item: { value: string },
        prefix: string,
      ) {
        const line = lines[cursorLine] ?? "";
        const newLines = [...lines];
        newLines[cursorLine] =
          line.slice(0, cursorCol - prefix.length) +
          item.value +
          line.slice(cursorCol);

        return {
          lines: newLines,
          cursorLine,
          cursorCol: cursorCol - prefix.length + item.value.length,
        };
      },
    },
    getReceivedOptions() {
      return receivedOptions;
    },
  };
}

test("withSnippets GIVEN a pi 0.63-style autocomplete provider WHEN delegating slash completions THEN it forwards autocomplete options", async () => {
  const { base, getReceivedOptions } = given_baseProviderExpectingOptions();
  const provider = withSnippets(base as never) as {
    getSuggestions(
      lines: string[],
      cursorLine: number,
      cursorCol: number,
      options?: unknown,
    ): Promise<
      | {
          items: Array<{ value: string; label: string }>;
          prefix: string;
        }
      | null
    >;
  };
  const options = {
    signal: new AbortController().signal,
    force: false,
  };

  const actualPromise = provider.getSuggestions(["/"], 0, 1, options);

  assert.ok(actualPromise instanceof Promise);

  const actual = await actualPromise;

  assert.deepEqual(getReceivedOptions(), options);
  assert.deepEqual(actual, {
    items: [{ value: "help", label: "help" }],
    prefix: "/",
  });
});

test("withSnippets GIVEN a snippet prefix WHEN requesting suggestions THEN it still returns a promise", async () => {
  const { base } = given_baseProviderExpectingOptions();
  const provider = withSnippets(base as never);

  const actualPromise = provider.getSuggestions(
    ["ask about $td"],
    0,
    "ask about $td".length,
    { signal: new AbortController().signal },
  );

  assert.ok(actualPromise instanceof Promise);

  const actual = await actualPromise;

  assert.ok(actual, "Expected snippet suggestions");
  assert.equal(actual?.prefix, "$td");
  assert.ok(
    actual?.items.some((item) => item.value === "$tdd"),
    "Expected matching snippet suggestion",
  );
});
