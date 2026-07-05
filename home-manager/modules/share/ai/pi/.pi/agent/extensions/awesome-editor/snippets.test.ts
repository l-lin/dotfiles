import assert from "node:assert/strict";
import test from "node:test";
import { withSnippets } from "./snippets.js";

type WrappedAutocompleteProvider = ReturnType<typeof withSnippets>;

function given_baseProviderExpectingOptions() {
  let receivedOptions: unknown;

  return {
    base: {
      getSuggestions(
        lines: string[],
        _cursorLine: number,
        _cursorCol: number,
        options?: unknown,
      ) {
        receivedOptions = options;

        if (!options || typeof options !== "object") {
          throw new TypeError("Missing autocomplete options");
        }

        if (!(lines[0] ?? "").startsWith("/")) {
          return null;
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

async function when_requestingSuggestions(
  provider: WrappedAutocompleteProvider,
  text: string,
) {
  return await provider.getSuggestions([text], 0, text.length, {
    signal: new AbortController().signal,
  });
}

test("withSnippets GIVEN a pi 0.63-style autocomplete provider WHEN delegating slash completions THEN it forwards autocomplete options", async () => {
  const { base, getReceivedOptions } = given_baseProviderExpectingOptions();
  const provider = withSnippets(base as never) as {
    getSuggestions(
      lines: string[],
      cursorLine: number,
      cursorCol: number,
      options?: unknown,
    ): Promise<{
      items: Array<{ value: string; label: string }>;
      prefix: string;
    } | null>;
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

test("withSnippets GIVEN a dollar query with no direct prefix match WHEN requesting suggestions THEN it returns fuzzy trigger matches after two characters", async () => {
  const { base } = given_baseProviderExpectingOptions();
  const provider = withSnippets(base as never);

  const actual = await when_requestingSuggestions(provider, "$ste");

  assert.ok(actual, "Expected snippet suggestions");
  assert.equal(actual.prefix, "$ste");
  assert.ok(
    actual.items.some((item) => item.value === "$feedback-steelman"),
    "Expected fuzzy trigger match for $feedback-steelman",
  );
});

test("withSnippets GIVEN a short dollar query WHEN requesting suggestions THEN prefix matches stay ahead of broader fuzzy matches", async () => {
  const { base } = given_baseProviderExpectingOptions();
  const provider = withSnippets(base as never);

  const actual = await when_requestingSuggestions(provider, "$st");
  const actualValues = actual?.items.map((item) => item.value) ?? [];
  const expectedPrefixValues = [
    "$stuck-blindspot",
    "$stuck-next-question",
    "$stuck-right-problem",
    "$stuck-simplest",
  ];

  assert.ok(actual, "Expected snippet suggestions");
  assert.deepEqual(
    actualValues.slice(0, expectedPrefixValues.length),
    expectedPrefixValues,
  );
  assert.ok(
    actualValues.indexOf("$feedback-steelman") >
      expectedPrefixValues.length - 1,
    "Expected fuzzy matches to appear after prefix matches",
  );
});

test("withSnippets GIVEN a question-mark snippet query with no direct prefix match WHEN requesting suggestions THEN it does not use fuzzy matching", async () => {
  const { base } = given_baseProviderExpectingOptions();
  const provider = withSnippets(base as never);

  const actual = await when_requestingSuggestions(provider, "?st");
  const expected = null;

  assert.equal(actual, expected);
});
