import assert from "node:assert/strict";
import test from "node:test";
import {
  given_component,
  then_cursor,
  then_yank_highlight,
  when_yank_settles,
} from "./test-helpers.js";

test("reply component GIVEN a successful yank WHEN the popup reflows THEN keeps the highlight on the same visible text", async () => {
  const { component } = given_component("abcdefghij", 24, () => {});

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("l");
  component.handleInput("y");
  await when_yank_settles();
  component.render(7);

  const actual = then_yank_highlight(component)?.text;

  assert.equal(actual, "abc");
  component.dispose();
});

test("reply component GIVEN a wrapped logical line WHEN using y$ THEN copies from the cursor to its logical line end", async () => {
  const yanked: string[] = [];
  const { component } = given_component("abcdefghij", 24, (text) => {
    yanked.push(text);
  });
  component.render(7);

  component.handleInput("l");
  component.handleInput("l");
  component.handleInput("y");
  component.handleInput("$");
  await when_yank_settles();

  const actual = yanked;
  const expected = ["cdefghij"];

  assert.deepEqual(actual, expected);
  component.dispose();
});

test("reply component GIVEN a wrapped logical line WHEN using y0 THEN copies to its logical line start without the cursor", async () => {
  const yanked: string[] = [];
  const { component } = given_component("abcdefghij", 24, (text) => {
    yanked.push(text);
  });
  component.render(7);

  component.handleInput("j");
  component.handleInput("l");
  component.handleInput("y");
  component.handleInput("0");
  await when_yank_settles();

  const actual = yanked;
  const expected = ["abcd"];

  assert.deepEqual(actual, expected);
  component.dispose();
});

test("reply component GIVEN normal mode WHEN using yiw and yfe THEN copies Vim ranges without moving the cursor", async () => {
  const yanked: string[] = [];
  const { component } = given_component("one two", 24, (text) => {
    yanked.push(text);
  });

  component.handleInput("y");
  component.handleInput("i");
  component.handleInput("w");
  await when_yank_settles();
  const actualAfterYiw = {
    yanked: [...yanked],
    cursor: then_cursor(component),
  };

  component.handleInput("0");
  component.handleInput("y");
  component.handleInput("f");
  component.handleInput("e");
  await when_yank_settles();
  const actualAfterYfe = {
    yanked: [...yanked],
    cursor: then_cursor(component),
  };

  assert.deepEqual(actualAfterYiw, {
    yanked: ["one"],
    cursor: { line: 0, grapheme: 0 },
  });
  assert.deepEqual(actualAfterYfe, {
    yanked: ["one", "one"],
    cursor: { line: 0, grapheme: 0 },
  });
  component.dispose();
});

test("reply component GIVEN Vim line motions WHEN using yy, Y, and yj THEN copies linewise ranges with document newlines", async () => {
  const yanked: string[] = [];
  const { component } = given_component("one\ntwo\nthree", 24, (text) => {
    yanked.push(text);
  });

  component.handleInput("y");
  component.handleInput("y");
  await when_yank_settles();
  component.handleInput("Y");
  await when_yank_settles();
  component.handleInput("y");
  component.handleInput("j");
  await when_yank_settles();

  assert.deepEqual(yanked, ["one\n", "one\n", "one\ntwo\n"]);
  component.dispose();
});

test("reply component GIVEN Vim outer-word motion WHEN using yaw THEN includes adjacent whitespace", async () => {
  const yanked: string[] = [];
  const { component } = given_component("one  two", 24, (text) => {
    yanked.push(text);
  });

  component.handleInput("y");
  component.handleInput("a");
  component.handleInput("w");
  await when_yank_settles();

  assert.deepEqual(yanked, ["one  "]);
  component.dispose();
});

test("reply component GIVEN a successful yank find WHEN repeating the character motion THEN remembers the yank find", async () => {
  const { component } = given_component("one two", 24, () => {});

  component.handleInput("y");
  component.handleInput("f");
  component.handleInput("e");
  await when_yank_settles();
  component.handleInput(";");

  assert.deepEqual(then_cursor(component), { line: 0, grapheme: 2 });
  component.dispose();
});

test("reply component GIVEN a successful yank WHEN 500 milliseconds pass THEN clears the highlight and requests a render", async () => {
  const { component, tui } = given_component("hello", 24, () => {});

  component.handleInput("y");
  component.handleInput("i");
  component.handleInput("w");
  await when_yank_settles();
  const requestsBeforeExpiry = tui.getRenderRequests();
  assert.notEqual(then_yank_highlight(component), null);

  await new Promise<void>((resolve) => setTimeout(resolve, 550));

  assert.equal(then_yank_highlight(component), null);
  assert.equal(tui.getRenderRequests() > requestsBeforeExpiry, true);
  component.dispose();
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
