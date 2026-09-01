import assert from "node:assert/strict";
import test from "node:test";
import { visibleWidth } from "@earendil-works/pi-tui";
import { ReplyComponent } from "./component.js";
import { DEFAULT_REPLY_KEYMAP } from "./settings.js";

function given_tui(rows = 24) {
  let renderRequests = 0;
  return {
    tui: {
      terminal: { rows },
      requestRender() {
        renderRequests++;
      },
    },
    getRenderRequests() {
      return renderRequests;
    },
  };
}

function given_theme() {
  return {
    fg(_color: string, text: string) {
      return text;
    },
    bg(_color: string, text: string) {
      return text;
    },
    bold(text: string) {
      return text;
    },
    underline(text: string) {
      return `\x1b[4m${text}\x1b[24m`;
    },
  };
}

function given_component(source: string, rows = 24) {
  const tui = given_tui(rows);
  let actualResult: unknown;
  const component = new ReplyComponent(
    tui.tui as never,
    given_theme() as never,
    source,
    DEFAULT_REPLY_KEYMAP,
    (result) => {
      actualResult = result;
    },
  );
  return {
    component,
    tui,
    getResult() {
      return actualResult;
    },
  };
}

function when_typing(component: ReplyComponent, text: string): void {
  for (const character of text) component.handleInput(character);
}

function then_cursor(component: ReplyComponent): {
  line: number;
  grapheme: number;
} {
  return {
    ...(component as unknown as { cursor: { line: number; grapheme: number } })
      .cursor,
  };
}

test("reply component GIVEN a source message WHEN selecting characters and submitting a comment THEN returns the annotated blocks on save", () => {
  const { component, getResult } = given_component("hello\nworld");

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("l");
  component.handleInput("\x1bc");
  assert.match(component.render(50).join("\n"), /# /);
  when_typing(component, "Use this wording");
  component.handleInput("\r");
  component.handleInput("\x13");

  const actual = getResult();
  const expected = {
    action: "save",
    text: "> hel\n\nUse this wording",
  };
  assert.deepEqual(actual, expected);
});

test("reply component GIVEN the default popup WHEN rendering THEN omits metadata and key-hint rows", () => {
  const { component } = given_component("hello");

  const actual = component.render(50).join("\n");

  assert.doesNotMatch(actual, /Latest assistant message/);
  assert.doesNotMatch(actual, /select/);
  assert.doesNotMatch(actual, /close/);
});

test("reply component GIVEN normal and visual modes WHEN q or Esc is pressed THEN q cancels and Esc does nothing outside comment input", () => {
  const { component, getResult } = given_component("hello");

  component.handleInput("\x1b");
  assert.equal(getResult(), undefined);

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("q");
  assert.equal(getResult(), undefined);

  component.handleInput("q");
  assert.deepEqual(getResult(), { action: "cancel" });
});

test("reply component GIVEN a visual selection WHEN Enter or Alt+C is pressed THEN only Alt+C opens the comment command row", () => {
  const { component } = given_component("hello");

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("\r");
  const afterEnter = component.render(50).join("\n");
  assert.doesNotMatch(afterEnter, /# /);

  component.handleInput("\x1bc");
  const actual = component.render(50).join("\n");
  assert.match(actual, /│ # \x1b/);
  assert.doesNotMatch(actual, /Comment on the selected text/);
});

test("reply component GIVEN a saved comment WHEN rendering THEN shows a full-width padded bordered comment box", () => {
  const { component } = given_component("hello");

  component.handleInput("v");
  component.handleInput("\x1bc");
  when_typing(component, "A comment");
  component.handleInput("\r");

  const actual = component.render(50).join("\n");
  assert.match(actual, /│╭─ #1 .*╮│/);
  assert.match(actual, /││ A comment .*││/);
  assert.match(actual, /│╰─+╯│/);
});

test("reply component GIVEN an annotation WHEN saving THEN invokes the insertion callback before closing", () => {
  const saveCalls: string[] = [];
  const tui = given_tui();
  let actualResult: unknown;
  const component = new ReplyComponent(
    tui.tui as never,
    given_theme() as never,
    "hello",
    DEFAULT_REPLY_KEYMAP,
    (result) => {
      actualResult = result;
    },
    (text) => saveCalls.push(text),
  );

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("\x1bc");
  when_typing(component, "A comment");
  component.handleInput("\r");
  component.handleInput("\x13");

  assert.deepEqual(saveCalls, ["> he\n\nA comment"]);
  assert.deepEqual(actualResult, {
    action: "save",
    text: "> he\n\nA comment",
  });
});

test("reply component GIVEN an existing annotation WHEN reopening with Ctrl+R THEN discards the draft and resets the popup", () => {
  const { component } = given_component("hello");

  component.handleInput("v");
  component.handleInput("\x1bc");
  when_typing(component, "A comment");
  component.handleInput("\r");
  assert.match(component.render(50).join("\n"), /A comment/);

  component.handleInput("\x12");

  assert.doesNotMatch(component.render(50).join("\n"), /A comment/);
});

test("reply component GIVEN an annotation WHEN rendering the source THEN underlines it without applying a foreground color", () => {
  const foregroundCalls: string[] = [];
  const theme = {
    ...given_theme(),
    fg(color: string, text: string) {
      foregroundCalls.push(`${color}:${text}`);
      return text;
    },
  };
  const tui = given_tui();
  const component = new ReplyComponent(
    tui.tui as never,
    theme as never,
    "hello",
    DEFAULT_REPLY_KEYMAP,
    () => {},
  );

  component.handleInput("v");
  component.handleInput("\x1bc");
  when_typing(component, "A comment");
  component.handleInput("\r");
  const actual = component.render(50).join("\n");

  assert.match(actual, /\x1b\[4m/);
  assert.equal(
    foregroundCalls.some((call) => call.endsWith(":h")),
    false,
  );
});

test("reply component GIVEN a line-wise selection WHEN saving a comment THEN quotes each selected logical line", () => {
  const { component, getResult } = given_component("one\ntwo\nthree");

  component.handleInput("V");
  component.handleInput("j");
  component.handleInput("\x1bc");
  when_typing(component, "Review both lines");
  component.handleInput("\r");
  component.handleInput("\x13");

  const actual = getResult();
  const expected = {
    action: "save",
    text: "> one\n> two\n\nReview both lines",
  };
  assert.deepEqual(actual, expected);
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

test("reply component GIVEN a pending g sequence WHEN receiving another motion THEN cancels g and processes that motion", () => {
  const { component } = given_component("first\nsecond");

  component.handleInput("g");
  component.handleInput("j");

  const actual = then_cursor(component);
  const expected = { line: 1, grapheme: 0 };

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

test("reply component GIVEN repeated characters on one line WHEN using f/t and repeats THEN searches without crossing lines", () => {
  const { component } = given_component("aXbXcXbX\nmissing b");

  component.handleInput("f");
  component.handleInput("b");
  const actualFind = then_cursor(component);
  component.handleInput(";");
  const actualRepeat = then_cursor(component);
  component.handleInput(",");
  const actualReverse = then_cursor(component);
  component.handleInput("0");
  component.handleInput("t");
  component.handleInput("b");
  const actualTill = then_cursor(component);
  component.handleInput(";");
  const actualTillRepeat = then_cursor(component);
  const expectedFind = { line: 0, grapheme: 2 };
  const expectedRepeat = { line: 0, grapheme: 6 };
  const expectedReverse = { line: 0, grapheme: 2 };
  component.handleInput("F");
  component.handleInput("b");
  const actualBackwardFind = then_cursor(component);
  component.handleInput("$");
  component.handleInput("T");
  component.handleInput("b");
  const actualBackwardTill = then_cursor(component);
  const expectedTill = { line: 0, grapheme: 1 };
  const expectedTillRepeat = { line: 0, grapheme: 5 };
  const expectedBackwardFind = { line: 0, grapheme: 2 };
  const expectedBackwardTill = { line: 0, grapheme: 7 };

  assert.deepEqual(actualFind, expectedFind);
  assert.deepEqual(actualRepeat, expectedRepeat);
  assert.deepEqual(actualReverse, expectedReverse);
  assert.deepEqual(actualTill, expectedTill);
  assert.deepEqual(actualTillRepeat, expectedTillRepeat);
  assert.deepEqual(actualBackwardFind, expectedBackwardFind);
  assert.deepEqual(actualBackwardTill, expectedBackwardTill);
});

test("reply component GIVEN a successful find WHEN a later find fails THEN preserves the repeat motion", () => {
  const { component } = given_component("aXbX");

  component.handleInput("f");
  component.handleInput("b");
  component.handleInput("0");
  component.handleInput("f");
  component.handleInput("z");
  component.handleInput(";");

  const actual = then_cursor(component);
  const expected = { line: 0, grapheme: 2 };

  assert.deepEqual(actual, expected);
});

test("reply component GIVEN a failed repeated find WHEN navigating back THEN comma still reverses the remembered search", () => {
  const { component } = given_component("bXbXb");

  component.handleInput("f");
  component.handleInput("b");
  component.handleInput(";");
  component.handleInput(";");
  component.handleInput("h");
  component.handleInput(",");

  const actual = then_cursor(component);
  const expected = { line: 0, grapheme: 2 };

  assert.deepEqual(actual, expected);
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

test("reply component GIVEN a character visual selection WHEN jumping with G THEN keeps the anchor for annotation", () => {
  const { component, getResult } = given_component("one\ntwo\nthree");

  component.handleInput("v");
  component.handleInput("G");
  component.handleInput("\x1bc");
  when_typing(component, "Review the opening");
  component.handleInput("\r");
  component.handleInput("\x13");

  const actual = getResult();
  const expected = {
    action: "save",
    text: "> one\n> two\n> t\n\nReview the opening",
  };

  assert.deepEqual(actual, expected);
});

test("reply component GIVEN a long source line WHEN rendering the popup THEN every rendered line fits the requested width", () => {
  const { component } = given_component(
    "A very long line with 中文 and emoji 🚀 that wraps several times",
    12,
  );

  const actual = component.render(32);
  const expected = actual.every((line) => visibleWidth(line) <= 32);

  assert.equal(expected, true);
});
