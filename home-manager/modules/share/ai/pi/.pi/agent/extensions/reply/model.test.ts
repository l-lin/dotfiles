import assert from "node:assert/strict";
import test from "node:test";
import {
  createSourceDocument,
  formatAnnotatedText,
  fromAssistantContent,
  getSelectionRange,
  type Annotation,
} from "./model.js";

test("reply model GIVEN text and non-text assistant blocks WHEN extracting the source THEN keeps text and labels other blocks", () => {
  const actual = fromAssistantContent([
    { type: "text", text: "First" },
    { type: "image" },
    { type: "toolCall", name: "read" },
    { type: "text", text: "Second" },
  ]);
  const expected = "First\n[image]\n[tool call]\nSecond";

  assert.equal(actual, expected);
});

test("reply model GIVEN thinking and redacted-thinking blocks WHEN extracting assistant content THEN omits them without removing other placeholders", () => {
  const actual = fromAssistantContent([
    { type: "text", text: "First" },
    { type: "thinking", thinking: "private reasoning" },
    { type: "redactedThinking" },
    { type: "redacted_thinking" },
    { type: "image" },
    { type: "text", text: "Second" },
  ]);
  const expected = "First\n[image]\nSecond";

  assert.equal(actual, expected);
});

test("reply model GIVEN a character-wise cursor range WHEN extracting the selection THEN preserves the exact selected substring", () => {
  const document = createSourceDocument("hello\nworld");
  const actual = getSelectionRange(
    document,
    { line: 0, grapheme: 1 },
    { line: 1, grapheme: 2 },
    "character",
  );
  const expected = { start: 1, end: 9, text: "ello\nwor" };

  assert.deepEqual(actual, expected);
});

test("reply model GIVEN a line-wise cursor range WHEN extracting the selection THEN includes complete logical lines and their boundaries", () => {
  const document = createSourceDocument("one\ntwo\nthree");
  const actual = getSelectionRange(
    document,
    { line: 1, grapheme: 0 },
    { line: 2, grapheme: 1 },
    "line",
  );
  const expected = { start: 4, end: 13, text: "two\nthree" };

  assert.deepEqual(actual, expected);
});

test("reply model GIVEN annotations created out of source order WHEN formatting them THEN preserves creation order and quotes every selected line", () => {
  const annotations: Annotation[] = [
    { id: 1, start: 8, end: 15, text: "another\n", comment: "Second comment" },
    { id: 2, start: 0, end: 4, text: "this", comment: "First comment" },
  ];
  const actual = formatAnnotatedText(annotations, "\n");
  const expected = "> another\n\nSecond comment\n\n> this\n\nFirst comment";

  assert.equal(actual, expected);
});
