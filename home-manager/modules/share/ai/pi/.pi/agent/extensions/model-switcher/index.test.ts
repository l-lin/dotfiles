import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import modelSelectorExtension from "./index.js";
import {
  formatModelReference,
  normalizeKeybind,
  rotateModels,
} from "./model-switching.js";
import { loadSettings, saveSettings } from "./settings.js";

function given_tempHome(t: test.TestContext): string {
  const previousHome = process.env.HOME;
  const previousXdgConfigHome = process.env.XDG_CONFIG_HOME;
  const tempHome = fs.mkdtempSync(path.join(os.tmpdir(), "model-selector-"));

  process.env.HOME = tempHome;
  delete process.env.XDG_CONFIG_HOME;

  t.after(() => {
    if (previousHome === undefined) delete process.env.HOME;
    else process.env.HOME = previousHome;

    if (previousXdgConfigHome === undefined) delete process.env.XDG_CONFIG_HOME;
    else process.env.XDG_CONFIG_HOME = previousXdgConfigHome;

    fs.rmSync(tempHome, { recursive: true, force: true });
  });

  return tempHome;
}

function given_mockPi(setModelResult = true) {
  const commands = new Map<string, { handler: Function }>();
  const shortcuts = new Map<string, { handler: Function }>();
  const setModelCalls: unknown[] = [];

  const pi = {
    on() {
      return undefined;
    },
    registerCommand(name: string, options: { handler: Function }) {
      commands.set(name, options);
    },
    registerShortcut(shortcut: string, options: { handler: Function }) {
      shortcuts.set(shortcut, options);
    },
    async setModel(model: unknown) {
      setModelCalls.push(model);
      return setModelResult;
    },
  };

  return { pi, commands, shortcuts, setModelCalls };
}

function given_mockContext(currentModelRef: string | undefined) {
  const notifications: Array<{ message: string; type?: string }> = [];
  const models = new Map<string, { provider: string; id: string }>([
    ["github-copilot/gpt-4.1", { provider: "github-copilot", id: "gpt-4.1" }],
    ["github-copilot/gpt-5.4", { provider: "github-copilot", id: "gpt-5.4" }],
  ]);

  const model = currentModelRef
    ? (models.get(currentModelRef) ?? {
        provider: currentModelRef.split("/")[0],
        id: currentModelRef.split("/").slice(1).join("/"),
      })
    : undefined;

  return {
    ctx: {
      model,
      modelRegistry: {
        find(provider: string, id: string) {
          return models.get(`${provider}/${id}`);
        },
      },
      ui: {
        notify(message: string, type?: string) {
          notifications.push({ message, type });
        },
      },
    },
    notifications,
  };
}

async function when_switchModelCommand(
  commandHandler: Function,
  ctx: unknown,
): Promise<void> {
  await commandHandler("", ctx);
}

test("rotateModels GIVEN current model in configured list WHEN rotating THEN next configured model becomes first", () => {
  const actual = rotateModels(
    ["github-copilot/gpt-4.1", "github-copilot/gpt-5.4"],
    "github-copilot/gpt-4.1",
  );
  const expected = ["github-copilot/gpt-5.4", "github-copilot/gpt-4.1"];

  assert.deepEqual(actual, expected);
});

test("rotateModels GIVEN current model outside configured list WHEN rotating THEN list rotates once from stored order", () => {
  const actual = rotateModels(
    [
      "github-copilot/gpt-4.1",
      "github-copilot/gpt-5.4",
      "github-copilot/gpt-4o",
    ],
    "github-copilot/other",
  );
  const expected = [
    "github-copilot/gpt-5.4",
    "github-copilot/gpt-4o",
    "github-copilot/gpt-4.1",
  ];

  assert.deepEqual(actual, expected);
});

test("normalizeKeybind GIVEN dash-separated modifier syntax WHEN normalizing THEN pi shortcut format is returned", () => {
  const actual = normalizeKeybind("alt-m");
  const expected = "alt+m";

  assert.equal(actual, expected);
});

test("formatModelReference GIVEN provider and model id WHEN formatting THEN provider slash model is returned", () => {
  const actual = formatModelReference({
    provider: "github-copilot",
    id: "gpt-5.4",
  });
  const expected = "github-copilot/gpt-5.4";

  assert.equal(actual, expected);
});

test("saveSettings GIVEN unrelated extension settings WHEN saving THEN sibling settings are preserved", (t) => {
  const tempHome = given_tempHome(t);
  const settingsPath = path.join(tempHome, ".pi", "agent", "settings.json");

  fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
  fs.writeFileSync(
    settingsPath,
    JSON.stringify(
      {
        extensionSettings: {
          webSearch: { enabled: false },
        },
      },
      null,
      2,
    ) + "\n",
  );

  saveSettings({
    keybind: "alt-m",
    models: ["github-copilot/gpt-4.1", "github-copilot/gpt-5.4"],
  });

  const actual = JSON.parse(fs.readFileSync(settingsPath, "utf8"));

  assert.deepEqual(actual.extensionSettings.webSearch, { enabled: false });
  assert.deepEqual(actual.extensionSettings.modelSelector, {
    keybind: "alt-m",
    models: ["github-copilot/gpt-4.1", "github-copilot/gpt-5.4"],
  });
});

test("extension GIVEN enabled settings WHEN loading THEN command and normalized shortcut are registered", (t) => {
  given_tempHome(t);
  saveSettings({
    keybind: "alt-m",
    models: ["github-copilot/gpt-4.1", "github-copilot/gpt-5.4"],
  });

  const { pi, commands, shortcuts } = given_mockPi();

  modelSelectorExtension(pi as never);

  assert.ok(commands.has("cmd:switch-model"));
  assert.ok(shortcuts.has("alt+m"));
});

test("extension GIVEN switch command WHEN invoked THEN it switches model and persists rotated order", async (t) => {
  given_tempHome(t);
  saveSettings({
    keybind: "alt-m",
    models: ["github-copilot/gpt-4.1", "github-copilot/gpt-5.4"],
  });

  const { pi, commands, setModelCalls } = given_mockPi();
  const { ctx, notifications } = given_mockContext("github-copilot/gpt-4.1");

  modelSelectorExtension(pi as never);

  const command = commands.get("cmd:switch-model");
  assert.ok(command, "Expected /cmd:switch-model to be registered");

  await when_switchModelCommand(command.handler, ctx);

  assert.deepEqual(setModelCalls, [
    { provider: "github-copilot", id: "gpt-5.4" },
  ]);
  assert.deepEqual(loadSettings().models, [
    "github-copilot/gpt-5.4",
    "github-copilot/gpt-4.1",
  ]);
  assert.deepEqual(notifications, [
    {
      message:
        "Switched model: github-copilot/gpt-4.1 → github-copilot/gpt-5.4",
      type: "info",
    },
  ]);
});

test("extension GIVEN switch command WHEN setModel fails THEN error is notified and model order is not persisted", async (t) => {
  given_tempHome(t);
  saveSettings({
    keybind: "alt-m",
    models: ["github-copilot/gpt-4.1", "github-copilot/gpt-5.4"],
  });

  const { pi, commands } = given_mockPi(false);
  const { ctx, notifications } = given_mockContext("github-copilot/gpt-4.1");

  modelSelectorExtension(pi as never);

  const command = commands.get("cmd:switch-model");
  assert.ok(command, "Expected /cmd:switch-model to be registered");

  await when_switchModelCommand(command.handler, ctx);

  assert.deepEqual(notifications, [
    {
      message: "Cannot switch to github-copilot/gpt-5.4: no API key available.",
      type: "error",
    },
  ]);
  assert.deepEqual(loadSettings().models, [
    "github-copilot/gpt-4.1",
    "github-copilot/gpt-5.4",
  ]);
});
