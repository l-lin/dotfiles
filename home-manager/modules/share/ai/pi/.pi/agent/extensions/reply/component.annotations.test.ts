import assert from "node:assert/strict";
import test from "node:test";
import { ReplyComponent } from "./component.js";
import { REPLY_KEYMAP } from "./settings.js";
import {
  given_component,
  given_theme,
  given_tui,
  then_cursor,
  then_scroll_top,
  then_visual_anchor,
  when_backspacing,
  when_typing,
} from "./test-helpers.js";

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

test("reply component GIVEN an annotation WHEN editing it with Alt+E THEN saves the replacement and keeps its range", () => {
  const { component, getResult } = given_component("hello");

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("\x1bc");
  when_typing(component, "A comment");
  component.handleInput("\r");
  component.handleInput("\x1be");
  component.handleInput("!");
  component.handleInput("\r");
  component.handleInput("\x13");

  const actual = getResult();
  const expected = {
    action: "save",
    text: "> he\n\nA comment!",
  };
  assert.deepEqual(actual, expected);
});

test("reply component GIVEN an annotation WHEN cancelling or submitting an empty edit THEN keeps the original comment", () => {
  const { component, getResult } = given_component("hello");

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("\x1bc");
  when_typing(component, "A comment");
  component.handleInput("\r");
  component.handleInput("\x1be");
  component.handleInput("\x1b");
  component.handleInput("\x1be");
  when_backspacing(component, "A comment");
  component.handleInput("\r");
  component.handleInput("\x13");

  const actual = getResult();
  const expected = {
    action: "save",
    text: "> he\n\nA comment",
  };
  assert.deepEqual(actual, expected);
});

test("reply component GIVEN overlapping annotations WHEN editing THEN edits the newest matching annotation first", () => {
  const { component, getResult } = given_component("hello");

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("\x1bc");
  when_typing(component, "First");
  component.handleInput("\r");
  component.handleInput("h");
  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("\x1bc");
  when_typing(component, "Second");
  component.handleInput("\r");
  component.handleInput("\x1be");
  component.handleInput("!");
  component.handleInput("\r");
  component.handleInput("\x13");

  const actual = getResult();
  const expected = {
    action: "save",
    text: "> he\n\nFirst\n\n> he\n\nSecond!",
  };
  assert.deepEqual(actual, expected);
});

test("reply component GIVEN an annotation WHEN deleting it with Alt+D THEN removes its comment and underline without confirmation", () => {
  const { component } = given_component("hello");

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("\x1bc");
  when_typing(component, "A comment");
  component.handleInput("\r");
  assert.match(component.render(50).join("\n"), /\x1b\[4m/);

  component.handleInput("\x1bd");

  const actual = component.render(50).join("\n");
  assert.doesNotMatch(actual, /A comment/);
  assert.doesNotMatch(actual, /\x1b\[4m/);
});

test("reply component GIVEN no annotation under the cursor WHEN using edit or delete THEN does nothing", () => {
  const { component, getResult } = given_component("hello");
  const before = component.render(50).join("\n");

  component.handleInput("\x1be");
  component.handleInput("\x1bd");

  const actual = {
    render: component.render(50).join("\n"),
    result: getResult(),
  };
  const expected = { render: before, result: undefined };
  assert.deepEqual(actual, expected);
});

test("reply component GIVEN an annotation WHEN the cursor leaves its range THEN edit and delete are no-ops", () => {
  const { component } = given_component("hello");

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("\x1bc");
  when_typing(component, "A comment");
  component.handleInput("\r");
  component.handleInput("l");
  const before = component.render(50).join("\n");

  component.handleInput("\x1be");
  component.handleInput("\x1bd");

  const actual = component.render(50).join("\n");
  assert.equal(actual, before);
});

test("reply component GIVEN an annotation WHEN saving THEN invokes the insertion callback before closing", () => {
  const saveCalls: string[] = [];
  const tui = given_tui();
  let actualResult: unknown;
  const component = new ReplyComponent(
    tui.tui as never,
    given_theme() as never,
    "hello",
    REPLY_KEYMAP,
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
    REPLY_KEYMAP,
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

test("reply component GIVEN a saved comment box WHEN using gj THEN skips its rendered rows", () => {
  const { component } = given_component("abcdefghij\nnext");

  component.handleInput("v");
  component.handleInput("\x1bc");
  when_typing(component, "Review this");
  component.handleInput("\r");
  component.render(7);

  when_typing(component, "gjgj");
  const actual = then_cursor(component);
  const expected = { line: 2, grapheme: 0 };

  assert.deepEqual(actual, expected);
});

test("reply component GIVEN comment input WHEN typing gj and gk THEN keeps those keys as comment text", () => {
  const { component } = given_component("hello");

  component.handleInput("v");
  component.handleInput("\x1bc");
  when_typing(component, "gjgk");
  component.handleInput("\r");

  const actual = component.render(50).join("\n");
  assert.match(actual, /gjgk/);
});

test("reply component GIVEN an annotated reply WHEN using zt in visual mode THEN counts annotation rows and preserves the selection", () => {
  const { component } = given_component("one\ntwo\nthree\nfour\nfive\nsix", 8);
  component.render(50);
  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("\x1bc");
  when_typing(component, "Review this");
  component.handleInput("\r");
  when_typing(component, "jj");
  const before = {
    cursor: then_cursor(component),
    anchor: then_visual_anchor(component),
  };

  when_typing(component, "zt");

  const actual = {
    scrollTop: then_scroll_top(component),
    cursor: then_cursor(component),
    anchor: then_visual_anchor(component),
  };
  const expected = {
    scrollTop: 5,
    ...before,
  };
  assert.deepEqual(actual, expected);
});

test("reply component GIVEN comment input WHEN receiving z THEN keeps z as comment text", () => {
  const { component } = given_component("hello");

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("\x1bc");
  component.handleInput("z");

  const actual = component.render(50).join("\n");
  assert.match(actual, /# z/);
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
