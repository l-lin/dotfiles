import assert from "node:assert/strict";
import path from "node:path";
import test from "node:test";
import skillBreakdownExtension from "./index.js";
import {
  given_keybindings,
  given_mockPi,
  given_readAssistantMessage,
  given_readToolResultMessage,
  given_sessionFile,
  given_sessionStartEntry,
  given_tempHome,
  given_theme,
  given_tui,
  when_computingBreakdown,
} from "./test-helpers.js";

test("extension GIVEN interactive mode and custom search keybindings WHEN navigating fuzzy matches THEN the selected search result follows those keybindings", async (t) => {
  const tempHome = given_tempHome(t);
  const sessionRoot = path.join(tempHome, ".pi", "agent", "sessions");
  const now = new Date();

  given_sessionFile({
    root: sessionRoot,
    fileName: "2026-04-09T08-00-00-000Z_alpha.jsonl",
    entries: [
      given_sessionStartEntry("2026-04-09T08:00:00.000Z", "/work/project-a"),
      given_readAssistantMessage("2026-04-09T08:00:01.000Z", [
        { id: "call-alpha", skillName: "skill-alpha", model: "model-alpha" },
      ]),
      given_readToolResultMessage({
        timestamp: "2026-04-09T08:00:02.000Z",
        toolCallId: "call-alpha",
      }),
    ],
  });
  given_sessionFile({
    root: sessionRoot,
    fileName: "2026-04-09T09-00-00-000Z_beta.jsonl",
    entries: [
      given_sessionStartEntry("2026-04-09T09:00:00.000Z", "/work/project-b"),
      given_readAssistantMessage("2026-04-09T09:00:01.000Z", [
        { id: "call-beta", skillName: "skill-beta", model: "model-beta" },
      ]),
      given_readToolResultMessage({
        timestamp: "2026-04-09T09:00:02.000Z",
        toolCallId: "call-beta",
      }),
    ],
  });

  const { pi, commands } = given_mockPi();
  skillBreakdownExtension(pi as never);

  const command = commands.get("cmd:skill-breakdown");
  assert.ok(command, "Expected /cmd:skill-breakdown to be registered");

  let overlayRender = "";
  let customCallCount = 0;
  const keybindings = given_keybindings({
    "tui.select.down": ["ctrl+n"],
    "tui.select.confirm": ["enter"],
    "tui.select.cancel": ["ctrl+]"],
  });

  await command.handler("", {
    hasUI: true,
    ui: {
      async custom(factory: Function, options?: unknown) {
        customCallCount += 1;
        if (!options) {
          return await when_computingBreakdown(sessionRoot, now);
        }

        const component = factory(
          given_tui(),
          given_theme(),
          keybindings,
          () => {},
        );
        component.handleInput("/");
        component.handleInput("s");
        component.handleInput("k");
        component.handleInput("i");
        component.handleInput("l");
        component.handleInput("l");
        component.handleInput("-");
        component.handleInput("ctrl+n");
        component.handleInput("enter");
        overlayRender = component.render(120).join("\n");
        return undefined;
      },
      notify() {},
    },
  });

  assert.equal(customCallCount, 2);
  assert.match(overlayRender, /skill: skill-alpha/i);
});
