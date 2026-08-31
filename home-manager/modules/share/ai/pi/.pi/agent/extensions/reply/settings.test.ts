import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { loadReplyKeymap } from "./settings.js";

function given_tempHome(t: test.TestContext): string {
  const previousHome = process.env.HOME;
  const tempHome = fs.mkdtempSync(path.join(os.tmpdir(), "reply-settings-"));
  process.env.HOME = tempHome;

  t.after(() => {
    if (previousHome === undefined) delete process.env.HOME;
    else process.env.HOME = previousHome;
    fs.rmSync(tempHome, { recursive: true, force: true });
  });

  return tempHome;
}

test("reply settings GIVEN a persisted reply keymap WHEN loading THEN applies the configured bindings", (t) => {
  const tempHome = given_tempHome(t);
  const settingsPath = path.join(tempHome, ".pi", "agent", "settings.json");
  fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
  fs.writeFileSync(
    settingsPath,
    JSON.stringify({
      extensionSettings: {
        reply: { open: "ctrl+o", left: "a", close: "x", comment: "alt+m" },
      },
    }),
  );

  const actual = loadReplyKeymap();
  const expected = {
    open: "ctrl+o",
    save: "ctrl+s",
    close: "x",
    comment: "alt+m",
    left: "a",
    down: "j",
    up: "k",
    right: "l",
    halfPageUp: "ctrl+u",
    halfPageDown: "ctrl+d",
    characterVisual: "v",
    lineVisual: "shift+v",
  };

  assert.deepEqual(actual, expected);
});
