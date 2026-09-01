import assert from "node:assert/strict";
import test from "node:test";
import {
  findCharMotionTarget,
  findWordMotionTarget,
  firstNonBlankColumn,
  isPrintableAscii,
} from "./motions.js";

function given_line(text: string): string[] {
  return text.split("");
}

test("vim motions GIVEN a line with repeated targets WHEN finding and repeating character motions THEN uses Vim till offsets", () => {
  const line = given_line("aXbXcXbX");
  const actual = {
    find: findCharMotionTarget(line, 0, "f", "b"),
    till: findCharMotionTarget(line, 0, "t", "b"),
    repeatedTill: findCharMotionTarget(line, 1, "t", "b", true),
    reversedTill: findCharMotionTarget(line, 5, "T", "b", true),
  };
  const expected = {
    find: 2,
    till: 1,
    repeatedTill: 5,
    reversedTill: 3,
  };

  assert.deepEqual(actual, expected);
});

test("vim motions GIVEN keyword and punctuation runs WHEN moving by words THEN follows Vim word units", () => {
  const lines = [given_line("one.two  three")];
  const actual = {
    firstWord: findWordMotionTarget(
      lines,
      { line: 0, column: 0 },
      "forward",
      "start",
    ),
    secondWord: findWordMotionTarget(
      lines,
      { line: 0, column: 3 },
      "forward",
      "start",
    ),
    firstEnd: findWordMotionTarget(
      lines,
      { line: 0, column: 0 },
      "forward",
      "end",
    ),
    punctuationEnd: findWordMotionTarget(
      lines,
      { line: 0, column: 2 },
      "forward",
      "end",
    ),
    backwards: findWordMotionTarget(
      lines,
      { line: 0, column: 4 },
      "backward",
      "start",
    ),
  };
  const expected = {
    firstWord: { line: 0, column: 3 },
    secondWord: { line: 0, column: 4 },
    firstEnd: { line: 0, column: 2 },
    punctuationEnd: { line: 0, column: 3 },
    backwards: { line: 0, column: 3 },
  };

  assert.deepEqual(actual, expected);
});

test("vim motions GIVEN empty and whitespace-only lines WHEN moving across the document THEN matches Vim line-boundary behavior", () => {
  const lines = [
    given_line("one"),
    given_line(""),
    given_line("   "),
    given_line("last"),
  ];
  const actual = {
    wordForwardToEmpty: findWordMotionTarget(
      lines,
      { line: 0, column: 2 },
      "forward",
      "start",
    ),
    wordForwardPastEmpty: findWordMotionTarget(
      lines,
      { line: 1, column: 0 },
      "forward",
      "start",
    ),
    wordBackwardToEmpty: findWordMotionTarget(
      lines,
      { line: 3, column: 0 },
      "backward",
      "start",
    ),
    wordEndPastEmpty: findWordMotionTarget(
      lines,
      { line: 1, column: 0 },
      "forward",
      "end",
    ),
  };
  const expected = {
    wordForwardToEmpty: { line: 1, column: 0 },
    wordForwardPastEmpty: { line: 3, column: 0 },
    wordBackwardToEmpty: { line: 1, column: 0 },
    wordEndPastEmpty: { line: 3, column: 3 },
  };

  assert.deepEqual(actual, expected);
});

test("vim motions GIVEN line boundaries WHEN resolving starts and ASCII find input THEN applies Vim-safe limits", () => {
  const actual = {
    indentedStart: firstNonBlankColumn(given_line("  first")),
    blankStart: firstNonBlankColumn(given_line("   ")),
    acceptsSpace: isPrintableAscii(" "),
    rejectsUnicode: isPrintableAscii("é"),
    rejectsControl: isPrintableAscii("\x1b"),
  };
  const expected = {
    indentedStart: 2,
    blankStart: 0,
    acceptsSpace: true,
    rejectsUnicode: false,
    rejectsControl: false,
  };

  assert.deepEqual(actual, expected);
});
