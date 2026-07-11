import assert from "node:assert/strict";
import test from "node:test";
import {
  formatParsedSnippetExpansion,
  parseSnippetExpansion,
  renderSnippetExpansion,
} from "./tabstops.js";

test("parseSnippetExpansion GIVEN valid numbered tabstops WHEN parsing THEN it returns plain text, sorted tabstops, and the explicit final stop", () => {
  const actual = parseSnippetExpansion("Hello ${2:world}, ${1:friend}$0!");
  const expected = {
    kind: "parsed",
    text: "Hello world, friend!",
    tabstops: [
      { index: 1, start: 13, end: 19 },
      { index: 2, start: 6, end: 11 },
    ],
    finalStop: 19,
    hasExplicitFinalStop: true,
  };

  assert.deepEqual(actual, expected);
});

test("parseSnippetExpansion GIVEN sparse tabstops and literal dollar amounts WHEN parsing THEN it keeps the dollars literal and uses the snippet end as the implicit final stop", () => {
  const actual = parseSnippetExpansion(
    "I'll tip you $200 if you explain ${3:queues}.",
  );
  const expectedText = "I'll tip you $200 if you explain queues.";
  const expected = {
    kind: "parsed",
    text: expectedText,
    tabstops: [
      {
        index: 3,
        start: expectedText.indexOf("queues"),
        end: expectedText.indexOf("queues") + "queues".length,
      },
    ],
    finalStop: expectedText.length,
    hasExplicitFinalStop: false,
  };

  assert.deepEqual(actual, expected);
});

test("parseSnippetExpansion GIVEN malformed placeholder syntax WHEN parsing THEN it falls back to the literal text", () => {
  const actual = parseSnippetExpansion("Hello ${1:topic");
  const expected = {
    kind: "literal",
    text: "Hello ${1:topic",
  };

  assert.deepEqual(actual, expected);
});

test("formatParsedSnippetExpansion GIVEN parsed tabstops WHEN rendering bracketed placeholders THEN it wraps each field and shifts the final stop", () => {
  const parsed = parseSnippetExpansion("Hello ${2:world}, ${1:friend}$0!");
  assert.equal(parsed.kind, "parsed");

  const actual = formatParsedSnippetExpansion(parsed, "bracketed");
  const expectedText = "Hello [world], [friend]!";
  const expected = {
    kind: "parsed",
    text: expectedText,
    tabstops: [
      {
        index: 1,
        start: expectedText.indexOf("[friend]"),
        end: expectedText.indexOf("[friend]") + "[friend]".length,
      },
      {
        index: 2,
        start: expectedText.indexOf("[world]"),
        end: expectedText.indexOf("[world]") + "[world]".length,
      },
    ],
    finalStop: expectedText.indexOf("!"),
    hasExplicitFinalStop: true,
  };

  assert.deepEqual(actual, expected);
});

test("renderSnippetExpansion GIVEN tabstop syntax WHEN rendering bracketed send-time placeholders THEN it keeps default text inside brackets and strips placeholder syntax", () => {
  const actual = renderSnippetExpansion(
    "Compare ${1:left} to ${2}$0 before deciding.",
    "bracketed",
  );
  const expected = "Compare [left] to [] before deciding.";

  assert.equal(actual, expected);
});
