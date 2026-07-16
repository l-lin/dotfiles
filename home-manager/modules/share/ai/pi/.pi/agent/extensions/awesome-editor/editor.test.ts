import assert from "node:assert/strict";
import test from "node:test";
import { AwesomeEditor } from "./editor.js";
import { withSnippets } from "./snippets.js";
import { CTRL_E, ESC_LEFT } from "./vim/types.js";

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
