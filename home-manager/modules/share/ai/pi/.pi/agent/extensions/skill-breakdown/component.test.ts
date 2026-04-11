import assert from "node:assert/strict";
import test from "node:test";
import { SkillBreakdownComponent } from "./component.js";
import {
  given_keybindings,
  given_readAssistantMessage,
  given_readToolResultMessage,
  given_sessionFile,
  given_sessionStartEntry,
  given_tempDirectory,
  given_theme,
  given_tui,
  when_computingBreakdown,
} from "./test-helpers.js";

async function given_component(
  t: test.TestContext,
  keybindingOverrides?: Record<string, string | string[]>,
) {
  const tempDirectory = given_tempDirectory(t);
  const now = new Date("2026-04-11T12:00:00.000Z");

  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-09T08-00-00-000Z_alpha.jsonl",
    entries: [
      given_sessionStartEntry("2026-04-09T08:00:00.000Z", "/work/project-a"),
      given_readAssistantMessage("2026-04-09T08:00:01.000Z", [
        { id: "call-alpha-1", skillName: "skill-alpha", model: "model-alpha" },
      ]),
      given_readToolResultMessage({
        timestamp: "2026-04-09T08:00:02.000Z",
        toolCallId: "call-alpha-1",
      }),
    ],
  });
  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-09T09-00-00-000Z_alpha-second.jsonl",
    entries: [
      given_sessionStartEntry("2026-04-09T09:00:00.000Z", "/work/project-a"),
      given_readAssistantMessage("2026-04-09T09:00:01.000Z", [
        { id: "call-alpha-2", skillName: "skill-alpha", model: "model-alpha" },
      ]),
      given_readToolResultMessage({
        timestamp: "2026-04-09T09:00:02.000Z",
        toolCallId: "call-alpha-2",
      }),
    ],
  });
  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-09T10-00-00-000Z_beta.jsonl",
    entries: [
      given_sessionStartEntry("2026-04-09T10:00:00.000Z", "/work/project-b"),
      given_readAssistantMessage("2026-04-09T10:00:01.000Z", [
        { id: "call-beta", skillName: "skill-beta", model: "model-beta" },
      ]),
      given_readToolResultMessage({
        timestamp: "2026-04-09T10:00:02.000Z",
        toolCallId: "call-beta",
      }),
    ],
  });
  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-09T11-00-00-000Z_gamma.jsonl",
    entries: [
      given_sessionStartEntry("2026-04-09T11:00:00.000Z", "/work/project-c"),
      given_readAssistantMessage("2026-04-09T11:00:01.000Z", [
        { id: "call-gamma", skillName: "skill-gamma", model: "model-gamma" },
      ]),
      given_readToolResultMessage({
        timestamp: "2026-04-09T11:00:02.000Z",
        toolCallId: "call-gamma",
      }),
    ],
  });

  const data = await when_computingBreakdown(tempDirectory, now);
  return new (SkillBreakdownComponent as any)(
    data,
    given_tui(),
    () => {},
    given_theme(),
    given_keybindings({
      "tui.select.down": ["down", "ctrl+n"],
      "tui.select.confirm": ["enter"],
      "tui.select.cancel": ["ctrl+]"],
      ...keybindingOverrides,
    }),
  ) as SkillBreakdownComponent;
}

test("SkillBreakdownComponent GIVEN fuzzy search results WHEN moving selection down and confirming THEN it opens the chosen skill summary instead of always picking the first match", async (t) => {
  const component = await given_component(t);

  component.handleInput("/");
  component.handleInput("s");
  component.handleInput("k");
  component.handleInput("i");
  component.handleInput("l");
  component.handleInput("l");
  component.handleInput("-");
  component.handleInput("down");
  component.handleInput("enter");

  const actual = component.render(120).join("\n");

  assert.match(actual, /skill: skill-alpha/i);
});

test("SkillBreakdownComponent GIVEN fuzzy search mode and a custom cancel keybinding WHEN cancelling THEN it exits search mode", async (t) => {
  const component = await given_component(t);

  component.handleInput("/");
  component.handleInput("s");
  component.handleInput("ctrl+]");

  const actual = component.render(120).join("\n");

  assert.doesNotMatch(actual, /search:/i);
});

test("SkillBreakdownComponent GIVEN fuzzy search mode and editor delete keybindings WHEN editing the query THEN it honors backward, word, and line deletions", async (t) => {
  const component = await given_component(t, {
    "tui.editor.deleteCharForward": ["ctrl+d"],
    "tui.editor.deleteWordBackward": ["ctrl+w", "alt+backspace"],
    "tui.editor.deleteWordForward": ["alt+d", "alt+delete"],
    "tui.editor.deleteToLineStart": ["ctrl+u"],
    "tui.editor.deleteToLineEnd": ["ctrl+k"],
  });

  component.handleInput("/");
  component.handleInput("a");
  component.handleInput("l");
  component.handleInput("p");
  component.handleInput("h");
  component.handleInput("a");
  component.handleInput(" ");
  component.handleInput("b");
  component.handleInput("e");
  component.handleInput("t");
  component.handleInput("a");
  component.handleInput("ctrl+d");
  component.handleInput("alt+d");
  component.handleInput("ctrl+k");
  component.handleInput("ctrl+w");

  const afterWordDelete = component.render(120).join("\n");
  assert.match(afterWordDelete, /search: alpha /i);

  component.handleInput("ctrl+u");

  const afterLineDelete = component.render(120).join("\n");
  assert.match(afterLineDelete, /search: …/i);
});
