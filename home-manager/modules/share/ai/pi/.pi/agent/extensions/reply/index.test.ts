import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import replyExtension, { getLastAssistantSource } from "./index.js";

function given_tempHome(t: test.TestContext): void {
  const previousHome = process.env.HOME;
  const tempHome = fs.mkdtempSync(path.join(os.tmpdir(), "reply-index-"));
  process.env.HOME = tempHome;

  t.after(() => {
    if (previousHome === undefined) delete process.env.HOME;
    else process.env.HOME = previousHome;
    fs.rmSync(tempHome, { recursive: true, force: true });
  });
}

test("reply extension GIVEN a saved annotation WHEN closing the popup THEN inserts it before the overlay render", async (t) => {
  given_tempHome(t);
  const events: string[] = [];
  let shortcutHandler: ((ctx: unknown) => Promise<void>) | undefined;
  const pi = {
    registerShortcut(_key: string, shortcut: { handler: Function }) {
      shortcutHandler = shortcut.handler as (ctx: unknown) => Promise<void>;
    },
  };
  const context = {
    mode: "tui",
    hasUI: true,
    sessionManager: {
      getBranch() {
        return [
          {
            type: "message",
            message: {
              role: "assistant",
              content: [{ type: "text", text: "hello" }],
            },
          },
        ];
      },
    },
    ui: {
      custom(factory: Function) {
        return new Promise((resolve) => {
          const component = factory(
            { terminal: { rows: 24 }, requestRender() {} },
            {
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
                return text;
              },
            },
            {},
            (result: unknown) => {
              events.push("done");
              resolve(result);
            },
          );
          component.handleInput("v");
          component.handleInput("l");
          component.handleInput("\x1bc");
          for (const character of "A comment") {
            component.handleInput(character);
          }
          component.handleInput("\r");
          component.handleInput("\x13");
        });
      },
      pasteToEditor(text: string) {
        events.push(`paste:${text}`);
      },
      notify() {},
    },
  };

  replyExtension(pi as never);
  assert.ok(shortcutHandler);
  await shortcutHandler(context);

  const actual = events;
  const expected = ["paste:> he\n\nA comment", "done"];
  assert.deepEqual(actual, expected);
});

test("reply extension GIVEN a branch with later tool and user entries WHEN finding the source THEN returns the latest assistant text", () => {
  const context = {
    sessionManager: {
      getBranch() {
        return [
          {
            type: "message",
            message: {
              role: "assistant",
              content: [{ type: "text", text: "Older" }],
            },
          },
          {
            type: "message",
            message: {
              role: "toolResult",
              content: [{ type: "text", text: "Tool output" }],
            },
          },
          {
            type: "message",
            message: {
              role: "assistant",
              content: [{ type: "text", text: "Latest" }],
            },
          },
          {
            type: "message",
            message: { role: "user", content: "Draft" },
          },
        ];
      },
    },
  };

  const actual = getLastAssistantSource(context as never);
  const expected = "Latest";

  assert.equal(actual, expected);
});

test("reply extension GIVEN an assistant message with no text block WHEN finding the source THEN returns no selectable source", () => {
  const context = {
    sessionManager: {
      getBranch() {
        return [
          {
            type: "message",
            message: { role: "assistant", content: [{ type: "image" }] },
          },
        ];
      },
    },
  };

  const actual = getLastAssistantSource(context as never);
  const expected = null;

  assert.equal(actual, expected);
});
