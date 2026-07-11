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

function given_editor() {
  return new AwesomeEditor(
    given_minimalTui() as never,
    given_minimalTheme() as never,
    given_minimalAppKeybindings() as never,
    "emacs",
  );
}

async function given_editorWithSelectedSnippet(trigger: string) {
  const actual = given_editor();
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
