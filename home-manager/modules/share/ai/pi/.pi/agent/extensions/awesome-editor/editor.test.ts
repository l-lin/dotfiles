import assert from "node:assert/strict";
import test from "node:test";
import { AwesomeEditor } from "./editor.js";
import { withSnippets } from "./snippets.js";
import { CTRL_E, ESC_LEFT } from "./vim-state.js";

type SnippetSuggestion = {
  items: Array<{ value: string; label: string }>;
  prefix: string;
};

function given_minimalTui() {
  return {
    requestRender() {},
    terminal: { rows: 24 },
  };
}

function given_minimalTheme() {
  return {
    borderColor(text: string) {
      return text;
    },
    selectList: {},
  };
}

function given_minimalAppKeybindings() {
  return {
    matches() {
      return false;
    },
  };
}

function given_baseAutocompleteProvider() {
  return {
    async getSuggestions() {
      return null;
    },
    applyCompletion(
      lines: string[],
      cursorLine: number,
      cursorCol: number,
      item: { value: string },
      prefix: string,
    ) {
      const line = lines[cursorLine] ?? "";
      const nextLines = [...lines];
      nextLines[cursorLine] =
        line.slice(0, cursorCol - prefix.length) +
        item.value +
        line.slice(cursorCol);

      return {
        lines: nextLines,
        cursorLine,
        cursorCol: cursorCol - prefix.length + item.value.length,
      };
    },
  };
}

function given_editor(editorMode: "emacs" | "vi" = "emacs") {
  return new AwesomeEditor(
    given_minimalTui() as never,
    given_minimalTheme() as never,
    given_minimalAppKeybindings() as never,
    editorMode,
  );
}

async function given_editorWithSelectedSnippet(
  trigger: string,
  editorMode: "emacs" | "vi" = "emacs",
) {
  const actual = given_editor(editorMode);
  const provider = withSnippets(given_baseAutocompleteProvider() as never) as {
    getSuggestions(
      lines: string[],
      cursorLine: number,
      cursorCol: number,
      options?: unknown,
    ): Promise<SnippetSuggestion | null>;
  };

  actual.setAutocompleteProvider(provider as never);
  actual.setText(trigger);

  const suggestions = await provider.getSuggestions(
    actual.getLines(),
    0,
    trigger.length,
    { signal: new AbortController().signal },
  );

  assert.ok(suggestions, "Expected snippet suggestions");

  (
    actual as unknown as {
      applyAutocompleteSuggestions(
        snippetSuggestions: SnippetSuggestion,
        state: string,
      ): void;
    }
  ).applyAutocompleteSuggestions(suggestions, "regular");

  return actual;
}

function when_typing(editor: AwesomeEditor, text: string): void {
  for (const character of text) {
    editor.handleInput(character);
  }
}

function when_bracketedPasting(editor: AwesomeEditor, text: string): void {
  editor.handleInput("\x1b[200~");
  editor.handleInput(text);
  editor.handleInput("\x1b[201~");
}

function given_placeholderSession(editor: AwesomeEditor) {
  return (editor as unknown as { placeholderSession: unknown })
    .placeholderSession;
}

test("awesome-editor GIVEN a question-mark snippet trigger typed as its own token WHEN pressing Ctrl-E THEN it expands the snippet", async () => {
  const editor = given_editor();

  editor.setAutocompleteProvider(
    withSnippets(given_baseAutocompleteProvider() as never) as never,
  );
  when_typing(editor, "?q");
  editor.handleInput(CTRL_E);

  const expectedText =
    "Use ask-user-question tool to reletenlessly interview me about every aspect of what I want until we reach a shared understanding.";
  const actual = {
    text: editor.getText(),
    cursor: editor.getCursor(),
  };
  const expected = {
    text: expectedText,
    cursor: { line: 0, col: expectedText.length },
  };

  assert.deepEqual(actual, expected);
});

test("awesome-editor GIVEN a snippet with one tabstop WHEN expanding it with Ctrl-E THEN it inserts bracketed placeholder text and moves the cursor inside the first field", async () => {
  const editor = await given_editorWithSelectedSnippet(
    "$understanding-overview",
  );

  editor.handleInput(CTRL_E);

  const expectedText =
    "Give me an overview of [topic], then tell me what the main debates or open questions are.";
  const actual = {
    text: editor.getText(),
    cursor: editor.getCursor(),
  };
  const expected = {
    text: expectedText,
    cursor: {
      line: 0,
      col: expectedText.indexOf("topic"),
    },
  };

  assert.deepEqual(actual, expected);
});

test("awesome-editor GIVEN a snippet with multiple tabstops WHEN typing and pressing Tab THEN it removes brackets from edited fields, advances to the next field, and exits at the final stop", async () => {
  const editor = await given_editorWithSelectedSnippet(
    "$understanding-next-steps",
  );

  editor.handleInput(CTRL_E);
  when_typing(editor, "queues");
  editor.handleInput("\t");

  const afterFirstTabText = editor.getText();
  const secondFieldStart = afterFirstTabText.indexOf("what we know");
  const actualAfterFirstTab = {
    text: afterFirstTabText,
    cursor: editor.getCursor(),
  };
  const expectedAfterFirstTab = {
    text: "Here's what I know so far about queues: [what we know]. What should I be reading or looking into next?",
    cursor: { line: 0, col: secondFieldStart },
  };

  assert.deepEqual(actualAfterFirstTab, expectedAfterFirstTab);

  when_typing(editor, "they already queue follow-up work");
  editor.handleInput("\t");

  const finalText =
    "Here's what I know so far about queues: they already queue follow-up work. What should I be reading or looking into next?";
  const actualAtFinalStop = {
    text: editor.getText(),
    cursor: editor.getCursor(),
    placeholderSession: given_placeholderSession(editor),
  };
  const expectedAtFinalStop = {
    text: finalText,
    cursor: { line: 0, col: finalText.length },
    placeholderSession: null,
  };

  assert.deepEqual(actualAtFinalStop, expectedAtFinalStop);
});

test("awesome-editor GIVEN untouched placeholders WHEN tabbing past them THEN it keeps the bracketed defaults in the buffer", async () => {
  const editor = await given_editorWithSelectedSnippet(
    "$understanding-next-steps",
  );

  editor.handleInput(CTRL_E);
  editor.handleInput("\t");
  editor.handleInput("\t");

  const finalText =
    "Here's what I know so far about [topic]: [what we know]. What should I be reading or looking into next?";
  const actual = {
    text: editor.getText(),
    cursor: editor.getCursor(),
    placeholderSession: given_placeholderSession(editor),
  };
  const expected = {
    text: finalText,
    cursor: { line: 0, col: finalText.length },
    placeholderSession: null,
  };

  assert.deepEqual(actual, expected);
});

test("awesome-editor GIVEN an active placeholder session WHEN the cursor moves off-road THEN it cancels placeholder mode", async () => {
  const editor = await given_editorWithSelectedSnippet(
    "$understanding-overview",
  );

  editor.handleInput(CTRL_E);
  editor.handleInput(ESC_LEFT);

  const actual = given_placeholderSession(editor);
  const expected = null;

  assert.equal(actual, expected);
});

test("awesome-editor GIVEN vi mode and an untouched placeholder WHEN Ghostty-style bracketed paste arrives THEN it replaces the whole field, preserves literal tabs, and still exits on Tab", async () => {
  const editor = await given_editorWithSelectedSnippet(
    "$understanding-overview",
    "vi",
  );

  editor.handleInput(CTRL_E);
  when_bracketedPasting(editor, "queue\tworkers");
  editor.handleInput("\t");

  const expectedText =
    "Give me an overview of queue\tworkers, then tell me what the main debates or open questions are.";
  const actual = {
    text: editor.getText(),
    cursor: editor.getCursor(),
    placeholderSession: given_placeholderSession(editor),
  };
  const expected = {
    text: expectedText,
    cursor: { line: 0, col: expectedText.length },
    placeholderSession: null,
  };

  assert.deepEqual(actual, expected);
});

test("awesome-editor GIVEN an edited placeholder WHEN the cursor stays inside the field and a paste arrives THEN it inserts at the cursor and keeps placeholder navigation alive", async () => {
  const editor = await given_editorWithSelectedSnippet(
    "$understanding-overview",
  );

  editor.handleInput(CTRL_E);
  when_typing(editor, "queues");
  editor.handleInput(ESC_LEFT);
  when_bracketedPasting(editor, "ing system");
  editor.handleInput("\t");

  const expectedText =
    "Give me an overview of queueing systems, then tell me what the main debates or open questions are.";
  const actual = {
    text: editor.getText(),
    cursor: editor.getCursor(),
    placeholderSession: given_placeholderSession(editor),
  };
  const expected = {
    text: expectedText,
    cursor: { line: 0, col: expectedText.length },
    placeholderSession: null,
  };

  assert.deepEqual(actual, expected);
});

test("awesome-editor GIVEN a multiline paste into the first placeholder WHEN tabbing forward THEN it keeps later placeholder navigation across lines", async () => {
  const editor = await given_editorWithSelectedSnippet(
    "$understanding-next-steps",
  );

  editor.handleInput(CTRL_E);
  when_bracketedPasting(editor, "queueing\nsystems");
  editor.handleInput("\t");

  const afterFirstTabText = editor.getText();
  const secondLine = editor.getLines()[1] ?? "";
  const actualAfterFirstTab = {
    text: afterFirstTabText,
    cursor: editor.getCursor(),
  };
  const expectedAfterFirstTab = {
    text: "Here's what I know so far about queueing\nsystems: [what we know]. What should I be reading or looking into next?",
    cursor: { line: 1, col: secondLine.indexOf("what we know") },
  };

  assert.deepEqual(actualAfterFirstTab, expectedAfterFirstTab);

  editor.handleInput("they already queue follow-up work");
  editor.handleInput("\t");

  const finalText =
    "Here's what I know so far about queueing\nsystems: they already queue follow-up work. What should I be reading or looking into next?";
  const actualAtFinalStop = {
    text: editor.getText(),
    cursor: editor.getCursor(),
    placeholderSession: given_placeholderSession(editor),
  };
  const expectedAtFinalStop = {
    text: finalText,
    cursor: { line: 1, col: finalText.split("\n")[1]!.length },
    placeholderSession: null,
  };

  assert.deepEqual(actualAtFinalStop, expectedAtFinalStop);
});

test("awesome-editor GIVEN a large placeholder paste WHEN the editor uses a paste marker THEN Tab still reaches the next placeholder", async () => {
  const editor = await given_editorWithSelectedSnippet(
    "$understanding-next-steps",
  );
  const largePaste = Array.from(
    { length: 11 },
    (_unusedLine, index) => `line ${index + 1}`,
  ).join("\n");

  editor.handleInput(CTRL_E);
  when_bracketedPasting(editor, largePaste);
  editor.handleInput("\t");

  const expectedText =
    "Here's what I know so far about [paste #1 +11 lines]: [what we know]. What should I be reading or looking into next?";
  const actual = {
    text: editor.getText(),
    cursor: editor.getCursor(),
    hasPlaceholderSession: given_placeholderSession(editor) !== null,
  };
  const expected = {
    text: expectedText,
    cursor: { line: 0, col: expectedText.indexOf("what we know") },
    hasPlaceholderSession: true,
  };

  assert.deepEqual(actual, expected);
});

test("awesome-editor GIVEN emacs mode and empty input WHEN alt-c is pressed THEN fenced codeblock is inserted and cursor is moved", () => {
  const editor = given_editor("emacs");

  editor.handleInput("\x1bc");
  const actual = {
    text: editor.getText(),
    cursor: editor.getCursor(),
  };

  const expected = {
    text: "```\n```",
    cursor: { line: 0, col: 3 },
  };
  assert.deepEqual(actual, expected);
});

test("awesome-editor GIVEN emacs mode and some input WHEN alt-c is pressed after a trailing newline THEN fenced codeblock is inserted and cursor is moved", () => {
  const editor = given_editor("emacs");

  when_typing(editor, "this is the first line\n");
  editor.handleInput("\x1bc");
  const actual = {
    text: editor.getText(),
    cursor: editor.getCursor(),
  };

  const expected = {
    text: "this is the first line\n```\n```",
    cursor: { line: 1, col: 3 },
  };
  assert.deepEqual(actual, expected);
});

test("awesome-editor GIVEN emacs mode and some input WHEN alt-c is pressed mid text THEN fenced codeblock is inserted and cursor is moved", () => {
  const editor = given_editor("emacs");

  when_typing(editor, "this is a mid-sentence");
  editor.handleInput("\x1bc");
  const actual = {
    text: editor.getText(),
    cursor: editor.getCursor(),
  };

  const expected = {
    text: "this is a mid-sentence```\n```",
    cursor: { line: 0, col: 3 },
  };
  assert.deepEqual(actual, expected);
});

test("awesome-editor GIVEN vi mode and indented lines WHEN using gg and G THEN jumps to Vim first-nonblank columns", () => {
  const editor = given_editor("vi");
  editor.setText("  first\none\n  last");
  editor.handleInput("\x1b");

  editor.handleInput("G");
  const actualAtLast = editor.getCursor();
  editor.handleInput("g");
  editor.handleInput("g");
  const actualAtFirst = editor.getCursor();
  const expectedAtLast = { line: 2, col: 2 };
  const expectedAtFirst = { line: 0, col: 2 };

  assert.deepEqual(actualAtLast, expectedAtLast);
  assert.deepEqual(actualAtFirst, expectedAtFirst);
});

test("awesome-editor GIVEN vi mode and Vim word units WHEN using w, b, and e THEN shares reply word navigation", () => {
  const editor = given_editor("vi");
  editor.setText("one.two  three");
  editor.handleInput("\x1b");
  editor.handleInput("0");

  editor.handleInput("w");
  const actualAfterFirstW = editor.getCursor();
  editor.handleInput("w");
  const actualAfterSecondW = editor.getCursor();
  editor.handleInput("b");
  const actualAfterB = editor.getCursor();
  editor.handleInput("0");
  editor.handleInput("e");
  const actualAfterE = editor.getCursor();
  const expectedAfterFirstW = { line: 0, col: 3 };
  const expectedAfterSecondW = { line: 0, col: 4 };
  const expectedAfterB = { line: 0, col: 3 };
  const expectedAfterE = { line: 0, col: 2 };

  assert.deepEqual(actualAfterFirstW, expectedAfterFirstW);
  assert.deepEqual(actualAfterSecondW, expectedAfterSecondW);
  assert.deepEqual(actualAfterB, expectedAfterB);
  assert.deepEqual(actualAfterE, expectedAfterE);
});

test("awesome-editor GIVEN vi mode and repeated targets WHEN using f/t with repeats THEN shares Vim character motions", () => {
  const editor = given_editor("vi");
  editor.setText("aXbXcXbX");
  editor.handleInput("\x1b");
  editor.handleInput("0");

  editor.handleInput("f");
  editor.handleInput("b");
  const actualFind = editor.getCursor();
  editor.handleInput(";");
  const actualRepeat = editor.getCursor();
  editor.handleInput(",");
  const actualReverse = editor.getCursor();
  editor.handleInput("0");
  editor.handleInput("t");
  editor.handleInput("b");
  const actualTill = editor.getCursor();
  editor.handleInput(";");
  const actualTillRepeat = editor.getCursor();
  const expectedFind = { line: 0, col: 2 };
  const expectedRepeat = { line: 0, col: 6 };
  const expectedReverse = { line: 0, col: 2 };
  editor.handleInput("F");
  editor.handleInput("b");
  const actualBackwardFind = editor.getCursor();
  editor.handleInput("$");
  editor.handleInput("T");
  editor.handleInput("b");
  const actualBackwardTill = editor.getCursor();
  const expectedTill = { line: 0, col: 1 };
  const expectedTillRepeat = { line: 0, col: 5 };
  const expectedBackwardFind = { line: 0, col: 2 };
  const expectedBackwardTill = { line: 0, col: 7 };

  assert.deepEqual(actualFind, expectedFind);
  assert.deepEqual(actualRepeat, expectedRepeat);
  assert.deepEqual(actualReverse, expectedReverse);
  assert.deepEqual(actualTill, expectedTill);
  assert.deepEqual(actualTillRepeat, expectedTillRepeat);
  assert.deepEqual(actualBackwardFind, expectedBackwardFind);
  assert.deepEqual(actualBackwardTill, expectedBackwardTill);
});

test("awesome-editor GIVEN a pending g sequence WHEN receiving another motion THEN cancels g and processes that motion", () => {
  const editor = given_editor("vi");
  editor.setText("first\nsecond\nthird");
  editor.handleInput("\x1b");
  editor.handleInput("g");
  editor.handleInput("g");

  editor.handleInput("g");
  editor.handleInput("j");

  const actual = editor.getCursor();
  const expected = { line: 1, col: 0 };

  assert.deepEqual(actual, expected);
});
