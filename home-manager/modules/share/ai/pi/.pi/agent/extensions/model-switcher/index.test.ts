import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import modelSelectorExtension from "./index.js";
import {
  CONFIGURED_MODELS,
  formatModelReference,
  normalizeKeybind,
  resolveConfiguredModel,
  rotateModels,
} from "./model-switching.js";
import { loadSettings } from "./settings.js";

// ─── helpers ────────────────────────────────────────────────────────────────

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

type ConfiguredModelTestShape = {
  reference: string;
  thinkingLevel?: string;
};

function given_configuredModel(
  configuredModel: unknown,
): ConfiguredModelTestShape {
  if (typeof configuredModel === "string") {
    return { reference: configuredModel };
  }

  if (
    configuredModel &&
    typeof configuredModel === "object" &&
    "reference" in configuredModel
  ) {
    const candidate = configuredModel as {
      reference?: unknown;
      thinkingLevel?: unknown;
    };

    if (typeof candidate.reference === "string") {
      const thinkingLevel =
        typeof candidate.thinkingLevel === "string"
          ? candidate.thinkingLevel
          : undefined;

      return thinkingLevel
        ? { reference: candidate.reference, thinkingLevel }
        : { reference: candidate.reference };
    }
  }

  throw new Error("Expected configured model to expose a reference string");
}

function given_configuredModelReferences(): string[] {
  return CONFIGURED_MODELS.map(
    (configuredModel) => given_configuredModel(configuredModel).reference,
  );
}

function given_mockPi(setModelResult = true) {
  const commands = new Map<string, { handler: Function }>();
  const shortcuts = new Map<string, { handler: Function }>();
  const setModelCalls: unknown[] = [];
  const setThinkingLevelCalls: string[] = [];

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
    setThinkingLevel(level: string) {
      setThinkingLevelCalls.push(level);
    },
  };

  return {
    pi,
    commands,
    shortcuts,
    setModelCalls,
    setThinkingLevelCalls,
  };
}

/** Builds a mock context whose registry is derived from CONFIGURED_MODELS. */
function given_mockContext(currentModelRef: string | undefined) {
  const notifications: Array<{ message: string; type?: string }> = [];
  const models = new Map(
    given_configuredModelReferences().map((ref) => {
      const slashIndex = ref.indexOf("/");
      const provider = ref.slice(0, slashIndex);
      const id = ref.slice(slashIndex + 1);
      return [ref, { provider, id }] as [
        string,
        { provider: string; id: string },
      ];
    }),
  );

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

// ─── CONFIGURED_MODELS ──────────────────────────────────────────────────────

test("CONFIGURED_MODELS WHEN imported THEN it includes the requested model references and thinking levels", () => {
  const actual = CONFIGURED_MODELS.map((configuredModel) =>
    given_configuredModel(configuredModel),
  );
  const expected = [
    { reference: "github-copilot/gpt-4.1" },
    { reference: "github-copilot/gpt-5.4", thinkingLevel: "xhigh" },
    { reference: "ollama/gemma4:26b", thinkingLevel: "high" },
  ];

  assert.deepEqual(actual, expected);
});

// ─── rotateModels ────────────────────────────────────────────────────────────

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

test("rotateModels GIVEN empty list WHEN rotating THEN empty list is returned", () => {
  const actual = rotateModels([], "github-copilot/gpt-4.1");

  assert.deepEqual(actual, []);
});

test("rotateModels GIVEN single model WHEN rotating THEN same single-element list is returned", () => {
  const actual = rotateModels(
    ["github-copilot/gpt-4.1"],
    "github-copilot/gpt-4.1",
  );

  assert.deepEqual(actual, ["github-copilot/gpt-4.1"]);
});

// ─── normalizeKeybind ────────────────────────────────────────────────────────

test("normalizeKeybind GIVEN dash-separated modifier syntax WHEN normalizing THEN pi shortcut format is returned", () => {
  const actual = normalizeKeybind("alt-m");
  const expected = "alt+m";

  assert.equal(actual, expected);
});

test("normalizeKeybind GIVEN already plus-separated format WHEN normalizing THEN it is returned unchanged", () => {
  const actual = normalizeKeybind("alt+m");

  assert.equal(actual, "alt+m");
});

test("normalizeKeybind GIVEN undefined WHEN normalizing THEN default alt+m is returned", () => {
  const actual = normalizeKeybind(undefined);

  assert.equal(actual, "alt+m");
});

test("normalizeKeybind GIVEN multi-modifier dash syntax WHEN normalizing THEN plus-separated format is returned", () => {
  const actual = normalizeKeybind("ctrl-shift-a");

  assert.equal(actual, "ctrl+shift+a");
});

// ─── formatModelReference ────────────────────────────────────────────────────

test("formatModelReference GIVEN provider and model id WHEN formatting THEN provider slash model is returned", () => {
  const actual = formatModelReference({
    provider: "github-copilot",
    id: "gpt-4.1",
  });
  const expected = "github-copilot/gpt-4.1";

  assert.equal(actual, expected);
});

test("formatModelReference GIVEN undefined model WHEN formatting THEN undefined is returned", () => {
  const actual = formatModelReference(undefined);

  assert.equal(actual, undefined);
});

// ─── resolveConfiguredModel ──────────────────────────────────────────────────

test("resolveConfiguredModel GIVEN malformed reference with no slash WHEN resolving THEN error is thrown", () => {
  const registry = { find: () => undefined };

  assert.throws(
    () => resolveConfiguredModel(registry, "invalid-no-slash"),
    /Invalid model reference/,
  );
});

test("resolveConfiguredModel GIVEN unknown model reference WHEN resolving THEN error is thrown", () => {
  const registry = { find: () => undefined };

  assert.throws(
    () => resolveConfiguredModel(registry, "provider/unknown-model"),
    /is not available/,
  );
});

test("resolveConfiguredModel GIVEN valid reference WHEN resolving THEN correct model object is returned", () => {
  const expectedModel = { provider: "github-copilot", id: "gpt-4.1" };
  const registry = { find: () => expectedModel };

  const actual = resolveConfiguredModel(registry, "github-copilot/gpt-4.1");

  assert.deepEqual(actual, expectedModel);
});

// ─── loadSettings ────────────────────────────────────────────────────────────

test("loadSettings GIVEN no settings file WHEN loading THEN default keybind is returned", (t) => {
  given_tempHome(t);

  const actual = loadSettings();

  assert.deepEqual(actual, { keybind: "alt-m" });
});

test("loadSettings GIVEN keybind in settings WHEN loading THEN configured keybind is returned", (t) => {
  const tempHome = given_tempHome(t);
  const settingsPath = path.join(tempHome, ".pi", "agent", "settings.json");
  fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
  fs.writeFileSync(
    settingsPath,
    JSON.stringify(
      { extensionSettings: { modelSelector: { keybind: "ctrl-k" } } },
      null,
      2,
    ) + "\n",
  );

  const actual = loadSettings();

  assert.deepEqual(actual, { keybind: "ctrl-k" });
});

// ─── extension integration ───────────────────────────────────────────────────

test("extension GIVEN default settings WHEN loading THEN command and normalized shortcut are registered", (t) => {
  given_tempHome(t);

  const { pi, commands, shortcuts } = given_mockPi();

  modelSelectorExtension(pi as never);

  assert.ok(commands.has("cmd:switch-model"));
  assert.ok(shortcuts.has("alt+m"));
});

test("extension GIVEN switch command WHEN invoked THEN it switches to next configured model", async (t) => {
  given_tempHome(t);

  const configuredModels = CONFIGURED_MODELS.map((configuredModel) =>
    given_configuredModel(configuredModel),
  );
  const { pi, commands, setModelCalls, setThinkingLevelCalls } = given_mockPi();
  const { ctx, notifications } = given_mockContext(
    configuredModels[0].reference,
  );

  modelSelectorExtension(pi as never);

  const command = commands.get("cmd:switch-model");
  assert.ok(command, "Expected /cmd:switch-model to be registered");

  await when_switchModelCommand(command.handler, ctx);

  const [firstProvider, ...firstId] = configuredModels[1].reference.split("/");
  assert.deepEqual(setModelCalls, [
    { provider: firstProvider, id: firstId.join("/") },
  ]);
  assert.deepEqual(setThinkingLevelCalls, ["xhigh"]);
  assert.deepEqual(notifications, [
    {
      message: `Switched model: ${configuredModels[0].reference} → ${configuredModels[1].reference}`,
      type: "info",
    },
  ]);
});

test("extension GIVEN current model with configured thinking WHEN switching THEN next model thinking level is updated", async (t) => {
  given_tempHome(t);

  const configuredModels = CONFIGURED_MODELS.map((configuredModel) =>
    given_configuredModel(configuredModel),
  );
  const { pi, commands, setModelCalls, setThinkingLevelCalls } = given_mockPi();
  const { ctx } = given_mockContext(configuredModels[1].reference);

  modelSelectorExtension(pi as never);

  const command = commands.get("cmd:switch-model");
  assert.ok(command, "Expected /cmd:switch-model to be registered");

  await when_switchModelCommand(command.handler, ctx);

  assert.equal(setModelCalls.length, 1, "Expected exactly one model switch");
  const switched = setModelCalls[0] as { provider: string; id: string };
  assert.equal(
    `${switched.provider}/${switched.id}`,
    configuredModels[2].reference,
  );
  assert.deepEqual(setThinkingLevelCalls, ["high"]);
});

test("extension GIVEN switch command WHEN setModel fails THEN error is notified", async (t) => {
  given_tempHome(t);

  const configuredModels = CONFIGURED_MODELS.map((configuredModel) =>
    given_configuredModel(configuredModel),
  );
  const { pi, commands } = given_mockPi(false);
  const { ctx, notifications } = given_mockContext(
    configuredModels[0].reference,
  );

  modelSelectorExtension(pi as never);

  const command = commands.get("cmd:switch-model");
  assert.ok(command, "Expected /cmd:switch-model to be registered");

  await when_switchModelCommand(command.handler, ctx);

  assert.deepEqual(notifications, [
    {
      message: `Cannot switch to ${configuredModels[1].reference}: no API key available.`,
      type: "error",
    },
  ]);
});

test("extension GIVEN no current model WHEN switching THEN advances to second configured model", async (t) => {
  given_tempHome(t);

  const configuredModels = CONFIGURED_MODELS.map((configuredModel) =>
    given_configuredModel(configuredModel),
  );
  const { pi, commands, setModelCalls, setThinkingLevelCalls } = given_mockPi();
  const { ctx } = given_mockContext(undefined);

  modelSelectorExtension(pi as never);

  const command = commands.get("cmd:switch-model");
  assert.ok(command, "Expected /cmd:switch-model to be registered");

  await when_switchModelCommand(command.handler, ctx);

  assert.equal(setModelCalls.length, 1, "Expected exactly one model switch");
  const switched = setModelCalls[0] as { provider: string; id: string };
  assert.equal(
    `${switched.provider}/${switched.id}`,
    configuredModels[1].reference,
  );
  assert.deepEqual(setThinkingLevelCalls, ["xhigh"]);
});

test("extension GIVEN current model is last in configured list WHEN switching THEN wraps to first model without changing thinking level", async (t) => {
  given_tempHome(t);

  const configuredModels = CONFIGURED_MODELS.map((configuredModel) =>
    given_configuredModel(configuredModel),
  );
  const lastModel = configuredModels[configuredModels.length - 1].reference;
  const { pi, commands, setModelCalls, setThinkingLevelCalls } = given_mockPi();
  const { ctx } = given_mockContext(lastModel);

  modelSelectorExtension(pi as never);

  const command = commands.get("cmd:switch-model");
  assert.ok(command, "Expected /cmd:switch-model to be registered");

  await when_switchModelCommand(command.handler, ctx);

  assert.equal(setModelCalls.length, 1, "Expected exactly one model switch");
  const switched = setModelCalls[0] as { provider: string; id: string };
  assert.equal(
    `${switched.provider}/${switched.id}`,
    configuredModels[0].reference,
  );
  assert.deepEqual(setThinkingLevelCalls, []);
});

test("extension GIVEN shortcut WHEN invoked THEN switches to next configured model and thinking level", async (t) => {
  given_tempHome(t);

  const configuredModels = CONFIGURED_MODELS.map((configuredModel) =>
    given_configuredModel(configuredModel),
  );
  const { pi, shortcuts, setModelCalls, setThinkingLevelCalls } =
    given_mockPi();
  const { ctx } = given_mockContext(configuredModels[0].reference);

  modelSelectorExtension(pi as never);

  const shortcut = shortcuts.get("alt+m");
  assert.ok(shortcut, "Expected alt+m shortcut to be registered");

  await shortcut.handler(ctx);

  assert.equal(
    setModelCalls.length,
    1,
    "Expected exactly one model switch via shortcut",
  );
  const switched = setModelCalls[0] as { provider: string; id: string };
  assert.equal(
    `${switched.provider}/${switched.id}`,
    configuredModels[1].reference,
  );
  assert.deepEqual(setThinkingLevelCalls, ["xhigh"]);
});
