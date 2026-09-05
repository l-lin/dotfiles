import assert from "node:assert/strict";
import test from "node:test";
import { initTheme } from "@earendil-works/pi-coding-agent";
import { visibleWidth } from "@earendil-works/pi-tui";
import {
  given_component,
  then_cursor,
  then_render_text,
  when_typing,
} from "./test-helpers.js";

test("reply component GIVEN Markdown content WHEN rendering THEN uses Pi's native Markdown formatting", () => {
  initTheme("dark", false);
  const { component } = given_component(
    "# Heading\n\nA **bold** paragraph.\n\n- first\n- second",
  );

  const actual = then_render_text(component);

  assert.match(actual, /│ Heading +│/);
  assert.match(actual, /│ A bold paragraph\. +│/);
  assert.match(actual, /│ - first +│/);
  assert.doesNotMatch(actual, /# Heading/);
});

test("reply component GIVEN bold Markdown WHEN selecting visible text THEN saves the rendered text", () => {
  initTheme("dark", false);
  const { component, getResult } = given_component("**hello**");

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("\x1bc");
  when_typing(component, "Review this");
  component.handleInput("\r");
  component.handleInput("\x13");

  const actual = getResult();
  const expected = {
    action: "save",
    text: "> he\n\nReview this",
  };

  assert.deepEqual(actual, expected);
});

test("reply component GIVEN Markdown reflow WHEN rendering at a new width THEN keeps the cursor on its visible character", () => {
  initTheme("dark", false);
  const { component } = given_component("abcdefghij");
  component.render(7);
  when_typing(component, "gj");

  component.render(20);

  const actual = then_cursor(component);
  const expected = { line: 0, grapheme: 3 };
  assert.deepEqual(actual, expected);
});

test("reply component GIVEN the default popup WHEN rendering THEN omits metadata and key-hint rows", () => {
  const { component } = given_component("hello");

  const actual = component.render(50).join("\n");

  assert.doesNotMatch(actual, /Latest assistant message/);
  assert.doesNotMatch(actual, /select/);
  assert.doesNotMatch(actual, /close/);
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
