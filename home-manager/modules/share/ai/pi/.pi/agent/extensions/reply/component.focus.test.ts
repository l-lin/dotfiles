import assert from "node:assert/strict";
import test from "node:test";
import { ReplyComponent } from "./component.js";
import { REPLY_KEYMAP } from "./settings.js";
import { given_theme, given_tui } from "./test-helpers.js";

test("reply component GIVEN an open comment input WHEN focus changes THEN propagates focus to Pi's input", () => {
  const tui = given_tui();
  const component = new ReplyComponent(
    tui.tui as never,
    given_theme() as never,
    "hello",
    REPLY_KEYMAP,
    () => {},
  );

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("\x1bc");
  component.focused = true;

  const input = (component as unknown as { promptInput: { focused: boolean } })
    .promptInput;
  const actual = input.focused;
  const expected = true;

  assert.equal(actual, expected);
});

test("reply component GIVEN an open search input WHEN focus changes THEN propagates focus to Pi's input", () => {
  const tui = given_tui();
  const component = new ReplyComponent(
    tui.tui as never,
    given_theme() as never,
    "hello",
    REPLY_KEYMAP,
    () => {},
  );

  component.handleInput("/");
  component.focused = true;
  component.focused = false;

  const input = (component as unknown as { promptInput: { focused: boolean } })
    .promptInput;
  const actual = input.focused;
  const expected = false;

  assert.equal(actual, expected);
});
