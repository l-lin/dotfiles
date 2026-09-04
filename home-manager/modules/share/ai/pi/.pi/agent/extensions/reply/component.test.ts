import assert from "node:assert/strict";
import test from "node:test";
import { initTheme } from "@earendil-works/pi-coding-agent";
import { visibleWidth } from "@earendil-works/pi-tui";
import { ReplyComponent } from "./component.js";
import { REPLY_KEYMAP } from "./settings.js";

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

function given_component(
  source: string,
  rows = 24,
  onYank?: (text: string) => void | Promise<void>,
  onYankError?: (error: unknown) => void,
) {
  const tui = given_tui(rows);
  let actualResult: unknown;
  const component = new ReplyComponent(
    tui.tui as never,
    given_theme() as never,
    source,
    REPLY_KEYMAP,
    (result) => {
      actualResult = result;
    },
    undefined,
    undefined,
    onYank,
    onYankError,
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

function when_backspacing(component: ReplyComponent, text: string): void {
  for (const _character of text) component.handleInput("\x7f");
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

function then_scroll_top(component: ReplyComponent): number {
  return (component as unknown as { scrollTop: number }).scrollTop;
}

function then_render_text(component: ReplyComponent): string {
  return component
    .render(50)
    .join("\n")
    .replace(/\x1b\[[0-9;]*m/gu, "");
}

async function when_yank_settles(): Promise<void> {
  await new Promise<void>((resolve) => setTimeout(resolve, 0));
}

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
    mode: (component as unknown as { mode: string }).mode,
    highlight: (component as unknown as { yankHighlight: unknown })
      .yankHighlight,
  };
  assert.deepEqual(actual.yanked, ["he"]);
  assert.deepEqual(actual.cursor, { line: 0, grapheme: 1 });
  assert.equal(actual.mode, "normal");
  assert.deepEqual(actual.highlight, { start: 0, end: 2, text: "he" });
  component.dispose();
});

test("reply component GIVEN a successful yank WHEN the popup reflows THEN keeps the highlight on the same visible text", async () => {
  const { component } = given_component("abcdefghij", 24, () => {});

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("l");
  component.handleInput("y");
  await when_yank_settles();
  component.render(7);

  const actual = (component as unknown as { yankHighlight: { text: string } })
    .yankHighlight.text;

  assert.equal(actual, "abc");
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
  assert.notEqual(
    (component as unknown as { yankHighlight: unknown }).yankHighlight,
    null,
  );

  await new Promise<void>((resolve) => setTimeout(resolve, 550));

  assert.equal(
    (component as unknown as { yankHighlight: unknown }).yankHighlight,
    null,
  );
  assert.equal(tui.getRenderRequests() > requestsBeforeExpiry, true);
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
    mode: (component as unknown as { mode: string }).mode,
    highlight: (component as unknown as { yankHighlight: unknown })
      .yankHighlight,
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
    anchor: {
      ...(
        component as unknown as {
          visualAnchor: { line: number; grapheme: number };
        }
      ).visualAnchor,
    },
  };

  when_typing(component, "zt");

  const actual = {
    scrollTop: then_scroll_top(component),
    cursor: then_cursor(component),
    anchor: {
      ...(
        component as unknown as {
          visualAnchor: { line: number; grapheme: number };
        }
      ).visualAnchor,
    },
  };
  const expected = {
    scrollTop: 5,
    ...before,
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

test("reply component GIVEN comment input WHEN receiving z THEN keeps z as comment text", () => {
  const { component } = given_component("hello");

  component.handleInput("v");
  component.handleInput("l");
  component.handleInput("\x1bc");
  component.handleInput("z");

  const actual = component.render(50).join("\n");
  assert.match(actual, /# z/);
});

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
    mode: (component as unknown as { mode: string }).mode,
    anchor: (
      component as unknown as {
        visualAnchor: { line: number; grapheme: number };
      }
    ).visualAnchor,
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
