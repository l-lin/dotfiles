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
    ):
      | Promise<{
          items: Array<{ value: string; label: string }>;
          prefix: string;
        } | null>
      | { items: Array<{ value: string; label: string }>; prefix: string }
      | null;
  };
  const options = {
    signal: new AbortController().signal,
    force: false,
  };

  const actual = await provider.getSuggestions(["/"], 0, 1, options);

  assert.deepEqual(getReceivedOptions(), options);
  assert.deepEqual(actual, {
    items: [{ value: "help", label: "help" }],
    prefix: "/",
  });
});
