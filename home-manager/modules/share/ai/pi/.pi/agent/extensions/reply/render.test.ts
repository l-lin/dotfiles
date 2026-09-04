import assert from "node:assert/strict";
import test from "node:test";
import { initTheme } from "@earendil-works/pi-coding-agent";
import { createSourceDocument, type Annotation } from "./model.js";
import {
  cellColumn,
  displayRowColumn,
  graphemeAtOrBeforeColumn,
  graphemeAtOrBeforeDisplayColumn,
  renderMarkdownDocument,
  ReplyRenderer,
  type ReplyRenderState,
} from "./render.js";

function given_theme() {
  return {
    fg(_color: string, text: string) {
      return text;
    },
    bg(_color: string, text: string) {
      return `[selected]${text}[/selected]`;
    },
    bold(text: string) {
      return text;
    },
    underline(text: string) {
      return `[underlined]${text}[/underlined]`;
    },
  };
}

function given_renderer(
  source: string,
  annotations: readonly Annotation[] = [],
  state: Partial<ReplyRenderState> = {},
): ReplyRenderer {
  return new ReplyRenderer(
    given_theme() as never,
    createSourceDocument(source),
    annotations,
    {
      cursor: { line: 0, grapheme: 0 },
      activeSelection: null,
      hasCommentInput: false,
      focused: false,
      ...state,
      searchMatches: state.searchMatches ?? [],
      currentSearchMatch: state.currentSearchMatch ?? null,
    },
  );
}

test("reply renderer GIVEN Markdown source WHEN rendering THEN uses Pi's Markdown rows and removes only renderer padding", () => {
  initTheme("dark", false);

  const actual = renderMarkdownDocument(
    "# Title\n\n- first\n- second\n\n```ts\nconst value = 1;\n```",
    30,
  );
  const expected =
    "Title\n\n- first\n- second\n\n```ts\n  const value = 1;\n```";

  assert.equal(actual.document.text, expected);
  assert.equal(actual.renderedLines.length, actual.document.lines.length);
});

test("reply renderer GIVEN native Markdown styling and a selection WHEN building rows THEN preserves both styles", () => {
  const annotations: Annotation[] = [];
  const renderer = new ReplyRenderer(
    given_theme() as never,
    createSourceDocument("Hello"),
    annotations,
    {
      cursor: { line: 0, grapheme: 0 },
      activeSelection: { start: 0, end: 1, text: "H" },
      searchMatches: [],
      currentSearchMatch: null,
      hasCommentInput: false,
      focused: false,
    },
    ["\x1b[1mHello\x1b[22m"],
  );

  const actual = renderer.buildDisplayRows(30)[0]!.content;

  assert.match(actual, /\x1b\[1m\x1b\[7m\[selected\]H\[\/selected\]/);
  assert.match(actual, /ello\x1b\[22m/);
});

test("reply renderer GIVEN a yank range WHEN building rows THEN highlights only the yanked graphemes with selected background", () => {
  const theme = {
    ...given_theme(),
    bg(color: string, text: string) {
      return color === "toolSuccessBg"
        ? `[yank]${text}[/yank]`
        : `[search]${text}[/search]`;
    },
  };
  const renderer = new ReplyRenderer(
    theme as never,
    createSourceDocument("abcd"),
    [],
    {
      cursor: { line: 0, grapheme: 0 },
      activeSelection: null,
      searchMatches: [],
      currentSearchMatch: null,
      yankHighlight: { start: 1, end: 2, text: "b" },
      hasCommentInput: false,
      focused: false,
    },
  );

  const actual = renderer.buildDisplayRows(30)[0]!.content;

  assert.match(actual, /\[yank\]b\[\/yank\]/);
  assert.doesNotMatch(actual, /\[yank\]a\[\/yank\]/);
  assert.doesNotMatch(actual, /\[yank\]d\[\/yank\]/);
});

test("reply renderer GIVEN an annotation ending on a source line WHEN building rows THEN places its comment box after that line", () => {
  const annotations: Annotation[] = [
    { id: 1, start: 0, end: 3, text: "one", comment: "Review this" },
  ];
  const renderer = given_renderer("one\ntwo", annotations);

  const actual = renderer.buildDisplayRows(30);
  const expected = ["source", "comment", "comment", "comment", "source"];

  assert.deepEqual(
    actual.map((row) => row.kind),
    expected,
  );
  assert.match(actual[2]!.content, /Review this/);
});

test("reply renderer GIVEN an annotated visual selection under the cursor WHEN building rows THEN keeps annotation and selection styles", () => {
  const annotations: Annotation[] = [
    { id: 1, start: 0, end: 1, text: "a", comment: "Review this" },
  ];
  const renderer = given_renderer("abcd", annotations, {
    cursor: { line: 0, grapheme: 1 },
    activeSelection: { start: 1, end: 3, text: "bc" },
  });

  const actual = renderer.buildDisplayRows(30)[0]!.content;

  assert.match(actual, /\[underlined\]a\[\/underlined\]/);
  assert.match(actual, /\x1b\[7m\[selected\]b\[\/selected\]\x1b\[27m/);
  assert.match(actual, /\[selected\]c\[\/selected\]/);
});

test("reply renderer GIVEN a wrapped source line WHEN finding the cursor row THEN returns the wrapped row containing the cursor", () => {
  const renderer = given_renderer("abcdef", [], {
    cursor: { line: 0, grapheme: 4 },
  });
  const rows = renderer.buildDisplayRows(4);

  const actual = renderer.findCursorRow(rows);
  const expected = 1;

  assert.equal(actual, expected);
});

test("reply renderer GIVEN a source line WHEN building rows THEN omits the line-number gutter", () => {
  const renderer = given_renderer("one", [], { hasCommentInput: true });

  const actual = renderer.buildDisplayRows(30)[0]!.content;

  assert.match(actual, /^one +$/);
  assert.doesNotMatch(actual, /│/);
});

test("reply renderer GIVEN search matches WHEN building source rows THEN highlights every match and distinguishes the current one", () => {
  const theme = {
    ...given_theme(),
    bg(color: string, text: string) {
      return color === "searchMatchBg" ? `[search]${text}[/search]` : text;
    },
    fg(color: string, text: string) {
      return color === "searchMatchText" ? `[current]${text}[/current]` : text;
    },
  };
  const renderer = new ReplyRenderer(
    theme as never,
    createSourceDocument("foo bar foo"),
    [],
    {
      cursor: { line: 0, grapheme: 0 },
      activeSelection: null,
      searchMatches: [
        { start: 0, end: 3 },
        { start: 8, end: 11 },
      ],
      currentSearchMatch: { start: 8, end: 11 },
      hasCommentInput: false,
      focused: false,
    },
  );

  const actual = renderer.buildDisplayRows(30)[0]!.content;

  assert.match(actual, /\[search\]f\[\/search\]/);
  assert.match(actual, /\[search\]o\[\/search\]\[search\]o/);
  assert.match(actual, /\[current\]\[search\]f\[\/search\]\[\/current\]/);
});

test("reply renderer GIVEN tab and wide graphemes WHEN converting columns THEN uses terminal display cells", () => {
  const line = createSourceDocument("a\t中").lines[0]!;

  const actual = {
    afterTab: cellColumn(line, 2),
    beforeWideCharacter: graphemeAtOrBeforeColumn(line, 3),
    atWideCharacter: graphemeAtOrBeforeColumn(line, 4),
  };
  const expected = {
    afterTab: 4,
    beforeWideCharacter: 1,
    atWideCharacter: 2,
  };

  assert.deepEqual(actual, expected);
});

test("reply renderer GIVEN wrapped source rows WHEN mapping display columns THEN preserves row-relative positions and clamps short rows", () => {
  const renderer = given_renderer("abcdefghij");
  const rows = renderer
    .buildDisplayRows(5)
    .filter((row) => row.kind === "source");
  const line = createSourceDocument("abcdefghij").lines[0]!;
  const firstRow = rows[0]!;
  const secondRow = rows[1]!;

  const actual = {
    currentColumn: displayRowColumn(line, secondRow, 7),
    targetAtColumn: graphemeAtOrBeforeDisplayColumn(line, firstRow, 2),
    targetPastEnd: graphemeAtOrBeforeDisplayColumn(line, firstRow, 20),
  };
  const expected = {
    currentColumn: 2,
    targetAtColumn: 2,
    targetPastEnd: 4,
  };

  assert.deepEqual(actual, expected);
});
