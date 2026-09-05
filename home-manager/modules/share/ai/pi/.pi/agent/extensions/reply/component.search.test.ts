import assert from "node:assert/strict";
import test from "node:test";
import { ReplyComponent } from "./component.js";
import { REPLY_KEYMAP } from "./settings.js";
import {
  given_component,
  given_theme,
  given_tui,
  then_cursor,
  then_mode,
  then_render_text,
  then_visual_anchor,
  when_typing,
} from "./test-helpers.js";

test("reply component GIVEN repeated literal text WHEN searching live THEN shows the count and navigates with n and N", () => {
  const { component } = given_component("foo bar foo");

  component.handleInput("/");
  const actualEmptyPrompt = component.render(50).join("\n");
  assert.match(actualEmptyPrompt, /\/\x1b\[7m \x1b\[27m/);
  when_typing(component, "foo");
  component.handleInput("\r");

  const actualFirst = {
    cursor: then_cursor(component),
    render: then_render_text(component),
  };
  component.handleInput("n");
  const actualSecond = {
    cursor: then_cursor(component),
    render: then_render_text(component),
  };
  component.handleInput("N");
  const actualPrevious = then_cursor(component);
  const expected = {
    firstCursor: { line: 0, grapheme: 0 },
    secondCursor: { line: 0, grapheme: 8 },
    previousCursor: { line: 0, grapheme: 0 },
  };

  assert.deepEqual(actualFirst.cursor, expected.firstCursor);
  assert.equal(actualFirst.render.includes("/foo [1/2]"), true);
  assert.deepEqual(actualSecond.cursor, expected.secondCursor);
  assert.equal(actualSecond.render.includes("/foo [2/2]"), true);
  assert.deepEqual(actualPrevious, expected.previousCursor);
});

test("reply component GIVEN an empty search prompt WHEN Enter is pressed THEN clears the search", () => {
  const { component } = given_component("foo bar");

  component.handleInput("/");
  component.handleInput("\r");

  const actual = then_render_text(component);

  assert.equal(actual.includes("/"), false);
});

test("reply component GIVEN an accepted search WHEN an empty replacement is submitted THEN clears the previous search", () => {
  const { component } = given_component("foo bar");

  when_typing(component, "/foo");
  component.handleInput("\r");
  component.handleInput("/");
  component.handleInput("\r");

  const actual = then_render_text(component);

  assert.equal(actual.includes("/foo"), false);
});

test("reply component GIVEN a search with no results WHEN typing live THEN shows a dash index over zero matches", () => {
  const { component } = given_component("foo bar");

  when_typing(component, "/missing");

  const actual = then_render_text(component);
  const expected = "/missing [-/0]";

  assert.equal(actual.includes(expected), true);
});

test("reply component GIVEN a backward search WHEN typing a newline escape THEN searches the full raw source", () => {
  const { component } = given_component("first\nsecond first");

  when_typing(component, "/\\nse");
  component.handleInput("\r");
  component.handleInput("G");
  component.handleInput("$");
  when_typing(component, "?first");
  component.handleInput("\r");

  const actual = {
    cursor: then_cursor(component),
    render: then_render_text(component),
  };
  const expected = {
    cursor: { line: 1, grapheme: 7 },
    status: "?first [2/2]",
  };

  assert.deepEqual(actual.cursor, expected.cursor);
  assert.equal(actual.render.includes(expected.status), true);
});

test("reply component GIVEN an accepted search WHEN cancelling a replacement search THEN restores the cursor and prior search", () => {
  const { component } = given_component("foo bar foo");

  when_typing(component, "/foo");
  component.handleInput("\r");
  component.handleInput("l");
  when_typing(component, "/bar");
  assert.deepEqual(then_cursor(component), { line: 0, grapheme: 4 });
  component.handleInput("\x1b");

  const actual = {
    cursor: then_cursor(component),
    render: then_render_text(component),
  };
  const expectedCursor = { line: 0, grapheme: 1 };

  assert.deepEqual(actual.cursor, expectedCursor);
  assert.equal(actual.render.includes("/foo [1/2]"), true);
  assert.equal(actual.render.includes("/bar"), false);
});

test("reply component GIVEN a keyword under the cursor WHEN using star and hash THEN searches the current word with Vim directions", () => {
  const { component } = given_component("foo bar foo");

  component.handleInput("*");
  const actualStar = {
    cursor: then_cursor(component),
    render: then_render_text(component),
  };
  component.handleInput("n");
  component.handleInput("#");
  const actualHash = {
    cursor: then_cursor(component),
    render: then_render_text(component),
  };

  assert.deepEqual(actualStar.cursor, { line: 0, grapheme: 0 });
  assert.equal(actualStar.render.includes("/foo [1/2]"), true);
  assert.deepEqual(actualHash.cursor, { line: 0, grapheme: 8 });
  assert.equal(actualHash.render.includes("?foo [2/2]"), true);
});

test("reply component GIVEN a cursor on punctuation WHEN using star THEN leaves the previous search unchanged", () => {
  const { component } = given_component("foo-bar");

  when_typing(component, "lll");
  component.handleInput("*");

  const actual = {
    cursor: then_cursor(component),
    render: then_render_text(component),
  };

  assert.deepEqual(actual.cursor, { line: 0, grapheme: 3 });
  assert.equal(actual.render.includes("[-/"), false);
});

test("reply component GIVEN a visual selection WHEN searching live THEN keeps its anchor while moving the endpoint", () => {
  const { component } = given_component("foo bar foo");

  component.handleInput("v");
  component.handleInput("l");
  when_typing(component, "/bar");

  const actual = {
    cursor: then_cursor(component),
    mode: then_mode(component),
    anchor: then_visual_anchor(component),
  };
  const expected = {
    cursor: { line: 0, grapheme: 4 },
    mode: "visual",
    anchor: { line: 0, grapheme: 0 },
  };

  assert.deepEqual(actual, expected);
});

test("reply component GIVEN an annotation WHEN searching live THEN keeps the comment box visible with the search prompt", () => {
  const { component } = given_component("foo bar");

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("\x1bc");
  when_typing(component, "Review this");
  component.handleInput("\r");
  when_typing(component, "/bar");

  const actual = then_render_text(component);

  assert.match(actual, /Review this/);
  assert.equal(actual.includes("/bar [1/1]"), true);
});

test("reply component GIVEN a refresh callback WHEN Ctrl-R is pressed THEN replaces the source and clears the draft", () => {
  const tui = given_tui();
  let refreshed = false;
  const component = new ReplyComponent(
    tui.tui as never,
    given_theme() as never,
    "old text",
    REPLY_KEYMAP,
    () => {},
    undefined,
    () => {
      refreshed = true;
      return "new text";
    },
  );

  when_typing(component, "/old");
  component.handleInput("\x12");

  const actual = then_render_text(component);

  assert.equal(refreshed, true);
  assert.match(actual, /new text/);
  assert.doesNotMatch(actual, /old text/);
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
