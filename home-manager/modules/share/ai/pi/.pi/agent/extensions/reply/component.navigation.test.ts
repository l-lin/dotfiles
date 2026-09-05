import assert from "node:assert/strict";
import test from "node:test";
import {
  given_component,
  then_cursor,
  then_mode,
  then_scroll_top,
  then_yank_highlight,
  when_typing,
  when_yank_settles,
} from "./test-helpers.js";

test("reply component GIVEN a visual selection WHEN y succeeds THEN copies it and exits visual mode", async () => {
  const yanked: string[] = [];
  const { component } = given_component("hello", 24, (text) => {
    yanked.push(text);
  });

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("y");
  await when_yank_settles();

  const actual = {
    yanked,
    cursor: then_cursor(component),
    mode: then_mode(component),
    highlight: then_yank_highlight(component),
  };
  assert.deepEqual(actual.yanked, ["he"]);
  assert.deepEqual(actual.cursor, { line: 0, grapheme: 1 });
  assert.equal(actual.mode, "normal");
  assert.deepEqual(actual.highlight, { start: 0, end: 2, text: "he" });
  component.dispose();
});

test("reply component GIVEN a clipboard failure WHEN visual y is used THEN notifies, exits visual mode, and clears the highlight", async () => {
  const errors: unknown[] = [];
  const { component } = given_component(
    "hello",
    24,
    () => Promise.reject(new Error("clipboard unavailable")),
    (error) => errors.push(error),
  );

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("y");
  await when_yank_settles();

  const actual = {
    errors: errors.length,
    mode: then_mode(component),
    highlight: then_yank_highlight(component),
  };
  assert.equal(actual.errors, 1);
  assert.equal(actual.mode, "normal");
  assert.equal(actual.highlight, null);
  component.dispose();
});

test("reply component GIVEN a visual selection WHEN uppercase Y succeeds THEN copies the literal visual range", async () => {
  const yanked: string[] = [];
  const { component } = given_component("one\ntwo\nthree", 24, (text) => {
    yanked.push(text);
  });

  component.handleInput("V");
  component.handleInput("j");
  component.handleInput("Y");
  await when_yank_settles();

  assert.deepEqual(yanked, ["one\ntwo\n"]);
  component.dispose();
});

test("reply component GIVEN multiple source lines WHEN using gg and G THEN jumps to Vim's first nonblank columns", () => {
  const { component } = given_component("  first\none\n  last");

  component.handleInput("G");
  const actualAtLast = then_cursor(component);
  component.handleInput("g");
  component.handleInput("g");
  const actualAtFirst = then_cursor(component);
  const expectedAtLast = { line: 2, grapheme: 2 };
  const expectedAtFirst = { line: 0, grapheme: 2 };

  assert.deepEqual(actualAtLast, expectedAtLast);
  assert.deepEqual(actualAtFirst, expectedAtFirst);
});

test("reply component GIVEN a wrapped source line WHEN using gj and gk THEN moves by display rows and preserves the screen column", () => {
  const { component } = given_component("abcdefghij");
  component.render(7);

  when_typing(component, "lllllll");
  when_typing(component, "gk");
  const actualAtFirstRow = then_cursor(component);
  when_typing(component, "gj");
  const actualAtSecondRow = then_cursor(component);
  const expectedAtFirstRow = { line: 0, grapheme: 2 };
  const expectedAtSecondRow = { line: 1, grapheme: 2 };

  assert.deepEqual(actualAtFirstRow, expectedAtFirstRow);
  assert.deepEqual(actualAtSecondRow, expectedAtSecondRow);
});

test("reply component GIVEN character visual mode WHEN using gj THEN extends the source selection across wrapped rows", () => {
  const { component, getResult } = given_component("abcdefghij");
  component.render(7);

  component.handleInput("v");
  component.handleInput("g");
  component.handleInput("j");
  component.handleInput("\x1bc");
  when_typing(component, "Review this");
  component.handleInput("\r");
  component.handleInput("\x13");

  const actual = getResult();
  const expected = {
    action: "save",
    text: "> abc\n> d\n\nReview this",
  };

  assert.deepEqual(actual, expected);
});

test("reply component GIVEN line visual mode WHEN using gj within one logical line THEN selects the whole logical line", () => {
  const { component, getResult } = given_component("abcdefghij");
  component.render(7);

  component.handleInput("V");
  when_typing(component, "gj");
  component.handleInput("\x1bc");
  when_typing(component, "Review this line");
  component.handleInput("\r");
  component.handleInput("\x13");

  const actual = getResult();
  const expected = {
    action: "save",
    text: "> abc\n> def\n\nReview this line",
  };

  assert.deepEqual(actual, expected);
});

test("reply component GIVEN a short target display row WHEN using gj and gk THEN clamps temporarily and restores the preferred column", () => {
  const { component } = given_component("abcdefg\nx");
  component.render(11);

  when_typing(component, "llll");
  when_typing(component, "gj");
  const actualAtWrappedRow = then_cursor(component);
  when_typing(component, "gj");
  const actualAtShortLine = then_cursor(component);
  when_typing(component, "gk");
  const actualAfterReturning = then_cursor(component);
  const expectedAtWrappedRow = { line: 1, grapheme: 0 };
  const expectedAtShortLine = { line: 1, grapheme: 0 };
  const expectedAfterReturning = { line: 0, grapheme: 4 };

  assert.deepEqual(actualAtWrappedRow, expectedAtWrappedRow);
  assert.deepEqual(actualAtShortLine, expectedAtShortLine);
  assert.deepEqual(actualAfterReturning, expectedAfterReturning);
});

test("reply component GIVEN a blank logical line WHEN using gj and gk THEN treats it as one row without losing the preferred column", () => {
  const { component } = given_component("abcdef\n\nklmnop");
  component.render(7);

  when_typing(component, "llll");
  when_typing(component, "gjgj");
  const actualAtBlankLine = then_cursor(component);
  when_typing(component, "gj");
  const actualAtNextLine = then_cursor(component);
  const expectedAtBlankLine = { line: 2, grapheme: 0 };
  const expectedAtNextLine = { line: 3, grapheme: 2 };

  assert.deepEqual(actualAtBlankLine, expectedAtBlankLine);
  assert.deepEqual(actualAtNextLine, expectedAtNextLine);
});

test("reply component GIVEN display-row motion at the source edges WHEN using gj and gk THEN clamps without wrapping around", () => {
  const { component } = given_component("first\nsecond");

  when_typing(component, "gk");
  const actualAtFirst = then_cursor(component);
  component.handleInput("G");
  when_typing(component, "gj");
  const actualAtLast = then_cursor(component);
  const expectedAtFirst = { line: 0, grapheme: 0 };
  const expectedAtLast = { line: 1, grapheme: 0 };

  assert.deepEqual(actualAtFirst, expectedAtFirst);
  assert.deepEqual(actualAtLast, expectedAtLast);
});

test("reply component GIVEN a pending g sequence WHEN receiving gj THEN uses display-row motion instead of ordinary j", () => {
  const { component } = given_component("first\nsecond");

  component.handleInput("g");
  component.handleInput("j");

  const actual = then_cursor(component);
  const expected = { line: 1, grapheme: 0 };

  assert.deepEqual(actual, expected);
});

test("reply component GIVEN a tall reply WHEN using zz, zt, and zb THEN aligns the active display row without moving the cursor", () => {
  const source = Array.from({ length: 15 }, (_, index) => `line ${index}`).join(
    "\n",
  );
  const { component } = given_component(source, 10);
  component.render(50);
  when_typing(component, "jjjjjj");
  const cursorBefore = then_cursor(component);

  when_typing(component, "zz");
  const actualCenter = then_scroll_top(component);
  when_typing(component, "zt");
  const actualTop = then_scroll_top(component);
  when_typing(component, "zb");
  const actualBottom = then_scroll_top(component);
  const actual = {
    center: actualCenter,
    top: actualTop,
    bottom: actualBottom,
    cursor: then_cursor(component),
  };
  const expected = {
    center: 3,
    top: 6,
    bottom: 1,
    cursor: cursorBefore,
  };

  assert.deepEqual(actual, expected);
});

test("reply component GIVEN a reply at the scroll bounds WHEN using z commands THEN clamps the viewport to valid rows", () => {
  const source = Array.from({ length: 15 }, (_, index) => `line ${index}`).join(
    "\n",
  );
  const { component } = given_component(source, 10);
  component.render(50);
  component.handleInput("G");

  when_typing(component, "zt");
  const actualTop = then_scroll_top(component);
  when_typing(component, "zb");
  const actualBottom = then_scroll_top(component);
  when_typing(component, "zz");
  const actualCenter = then_scroll_top(component);

  const actual = { top: actualTop, bottom: actualBottom, center: actualCenter };
  const expected = { top: 9, bottom: 9, center: 9 };
  assert.deepEqual(actual, expected);

  const short = given_component("one\ntwo\nthree", 10);
  short.component.render(50);
  short.component.handleInput("G");
  when_typing(short.component, "zz");
  assert.equal(then_scroll_top(short.component), 0);
});

test("reply component GIVEN a wrapped reply WHEN using zt THEN anchors the cursor's exact display row", () => {
  const { component } = given_component("abcdefghij", 5);
  component.render(7);
  when_typing(component, "gj");
  const cursorBefore = then_cursor(component);

  when_typing(component, "zt");

  const actual = {
    scrollTop: then_scroll_top(component),
    cursor: then_cursor(component),
  };
  const expected = {
    scrollTop: 1,
    cursor: cursorBefore,
  };
  assert.deepEqual(actual, expected);
});

test("reply component GIVEN an explicit viewport position WHEN moving within view THEN keeps that position until visibility requires a change", () => {
  const source = Array.from({ length: 15 }, (_, index) => `line ${index}`).join(
    "\n",
  );
  const { component } = given_component(source, 10);
  component.render(50);
  when_typing(component, "jjjjjjzt");
  component.handleInput("j");
  component.render(50);

  const actual = then_scroll_top(component);
  const expected = 6;
  assert.equal(actual, expected);
});

test("reply component GIVEN a pending z sequence WHEN receiving an unsupported key THEN reprocesses that key without window positioning", () => {
  const { component } = given_component("first\nsecond", 5);
  component.render(50);

  component.handleInput("z");
  component.handleInput("j");
  const actualAfterInvalid = {
    scrollTop: then_scroll_top(component),
    cursor: then_cursor(component),
  };
  const expectedAfterInvalid = {
    scrollTop: 0,
    cursor: { line: 1, grapheme: 0 },
  };

  assert.deepEqual(actualAfterInvalid, expectedAfterInvalid);
});

test("reply component GIVEN an unsupported g sequence WHEN receiving the second key THEN processes that key normally", () => {
  const { component, getResult } = given_component("first");

  component.handleInput("g");
  component.handleInput("q");

  const actual = getResult();
  const expected = { action: "cancel" };

  assert.deepEqual(actual, expected);
});

test("reply component GIVEN Vim word units WHEN using w, b, and e THEN moves across keyword and punctuation runs", () => {
  const { component } = given_component("one.two  three");

  component.handleInput("w");
  const actualAfterFirstW = then_cursor(component);
  component.handleInput("w");
  const actualAfterSecondW = then_cursor(component);
  component.handleInput("b");
  const actualAfterB = then_cursor(component);
  component.handleInput("0");
  component.handleInput("e");
  const actualAfterE = then_cursor(component);
  const expectedAfterFirstW = { line: 0, grapheme: 3 };
  const expectedAfterSecondW = { line: 0, grapheme: 4 };
  const expectedAfterB = { line: 0, grapheme: 3 };
  const expectedAfterE = { line: 0, grapheme: 2 };

  assert.deepEqual(actualAfterFirstW, expectedAfterFirstW);
  assert.deepEqual(actualAfterSecondW, expectedAfterSecondW);
  assert.deepEqual(actualAfterB, expectedAfterB);
  assert.deepEqual(actualAfterE, expectedAfterE);
});

test("reply component GIVEN an indented source line WHEN using 0, _, and $ THEN moves to Vim line edges", () => {
  const { component } = given_component("  first");

  component.handleInput("_");
  const actualNonblank = then_cursor(component);
  component.handleInput("$");
  const actualEnd = then_cursor(component);
  component.handleInput("0");
  const actualStart = then_cursor(component);
  const expectedNonblank = { line: 0, grapheme: 2 };
  const expectedEnd = { line: 0, grapheme: 6 };
  const expectedStart = { line: 0, grapheme: 0 };

  assert.deepEqual(actualNonblank, expectedNonblank);
  assert.deepEqual(actualEnd, expectedEnd);
  assert.deepEqual(actualStart, expectedStart);
});

test("reply component GIVEN a pending find motion WHEN receiving invalid input or Escape THEN cancels without moving or closing", () => {
  const { component, getResult } = given_component("hello");

  component.handleInput("f");
  component.handleInput("é");
  const actualAfterInvalid = then_cursor(component);
  component.handleInput("f");
  component.handleInput("\x1b");
  const actualAfterEscape = then_cursor(component);
  const actualResult = getResult();
  const expected = { line: 0, grapheme: 0 };

  assert.deepEqual(actualAfterInvalid, expected);
  assert.deepEqual(actualAfterEscape, expected);
  assert.equal(actualResult, undefined);
});

test("reply component GIVEN a character visual selection WHEN o is pressed THEN swaps the active cursor and anchor", () => {
  const { component, getResult } = given_component("hello");

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("o");
  component.handleInput("l");
  component.handleInput("l");
  component.handleInput("\x1bc");
  when_typing(component, "Review the middle");
  component.handleInput("\r");
  component.handleInput("\x13");

  const actual = getResult();
  const expected = {
    action: "save",
    text: "> el\n\nReview the middle",
  };

  assert.deepEqual(actual, expected);
});
