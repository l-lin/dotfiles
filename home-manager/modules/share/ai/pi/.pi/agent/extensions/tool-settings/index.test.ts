import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {
  loadEnabledSettings,
  readExtensionSettings,
  registerEnabledToggleCommand,
  saveExtensionSettings,
} from "./index.js";

function given_mockPi(activeTools: string[] = []) {
  const registeredCommands = new Map<
    string,
    { description?: string; handler: Function }
  >();
  const emittedEvents: Array<{ event: string; payload: unknown }> = [];
  const setActiveToolsCalls: string[][] = [];
  let currentActiveTools = [...activeTools];

  return {
    pi: {
      registerCommand(
        name: string,
        options: { description?: string; handler: Function },
      ) {
        registeredCommands.set(name, options);
      },
      getActiveTools() {
        return [...currentActiveTools];
      },
      setActiveTools(next: string[]) {
        currentActiveTools = [...next];
        setActiveToolsCalls.push([...next]);
      },
      events: {
        emit(event: string, payload: unknown) {
          emittedEvents.push({ event, payload });
        },
      },
    },
    registeredCommands,
    emittedEvents,
    setActiveToolsCalls,
  };
}

function given_mockContext() {
  const notifications: Array<{ message: string; type?: string }> = [];

  return {
    ctx: {
      ui: {
        notify(message: string, type?: string) {
          notifications.push({ message, type });
        },
      },
    },
    notifications,
  };
}

function given_tempHome(t: test.TestContext): string {
  const previousHome = process.env.HOME;
  const previousXdgConfigHome = process.env.XDG_CONFIG_HOME;
  const tempHome = fs.mkdtempSync(path.join(os.tmpdir(), "tool-settings-"));

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

function given_savedSettingsFile(tempHome: string, settings: unknown): string {
  const settingsPath = path.join(tempHome, ".pi", "agent", "settings.json");
  fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
  fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + "\n");
  return settingsPath;
}

function given_fileBlockingSettingsDirectory(tempHome: string): void {
  const piDirectoryPath = path.join(tempHome, ".pi");
  fs.writeFileSync(piDirectoryPath, "blocked", "utf8");
}

function when_readingSavedSettingsFile(tempHome: string): unknown {
  const settingsPath = path.join(tempHome, ".pi", "agent", "settings.json");
  return JSON.parse(fs.readFileSync(settingsPath, "utf8"));
}

async function when_runningCommand(
  commandHandler: Function,
  ctx: unknown,
): Promise<void> {
  await commandHandler("", ctx);
}

test("registerEnabledToggleCommand GIVEN a tool-backed extension WHEN toggled THEN it persists state, updates active tools, and emits a change event", async (t) => {
  const tempHome = given_tempHome(t);
  const { pi, registeredCommands, emittedEvents, setActiveToolsCalls } =
    given_mockPi(["read", "web-fetch"]);
  const { ctx, notifications } = given_mockContext();
  const settings = { enabled: true };

  registerEnabledToggleCommand(pi as never, {
    toolName: "web-fetch",
    extensionKey: "webFetch",
    description: "Toggle web-fetch tool on/off",
    settings,
  });

  const command = registeredCommands.get("cmd:web-fetch-toggle");
  assert.ok(command, "Expected toggle command to be registered");

  await when_runningCommand(command.handler, ctx);

  const actualSettingsFile = when_readingSavedSettingsFile(tempHome) as {
    extensionSettings: { webFetch: { enabled: boolean } };
  };

  assert.equal(settings.enabled, false);
  assert.equal(actualSettingsFile.extensionSettings.webFetch.enabled, false);
  assert.deepEqual(setActiveToolsCalls, [["read"]]);
  assert.deepEqual(emittedEvents, [
    {
      event: "custom-tool:changed",
      payload: { tool: "web-fetch", enabled: false },
    },
  ]);
  assert.deepEqual(notifications, [
    { message: "web-fetch disabled", type: "info" },
  ]);
});

test("registerEnabledToggleCommand GIVEN a save failure WHEN toggled THEN it keeps in-memory state unchanged", async (t) => {
  const tempHome = given_tempHome(t);
  given_fileBlockingSettingsDirectory(tempHome);
  const { pi, registeredCommands, emittedEvents, setActiveToolsCalls } =
    given_mockPi(["read", "web-fetch"]);
  const { ctx, notifications } = given_mockContext();
  const settings = { enabled: true };

  registerEnabledToggleCommand(pi as never, {
    toolName: "web-fetch",
    extensionKey: "webFetch",
    description: "Toggle web-fetch tool on/off",
    settings,
  });

  const command = registeredCommands.get("cmd:web-fetch-toggle");
  assert.ok(command, "Expected toggle command to be registered");

  await assert.rejects(() => when_runningCommand(command.handler, ctx));

  assert.equal(settings.enabled, true);
  assert.deepEqual(setActiveToolsCalls, []);
  assert.deepEqual(emittedEvents, []);
  assert.deepEqual(notifications, []);
});

test("saveExtensionSettings GIVEN sibling and existing extension settings WHEN saving THEN enabled is updated without losing other keys", (t) => {
  const tempHome = given_tempHome(t);
  given_savedSettingsFile(tempHome, {
    sessionName: "demo",
    extensionSettings: {
      webFetch: { retries: 2 },
      webSearch: { enabled: false },
    },
  });

  saveExtensionSettings({
    extensionKey: "webFetch",
    enabled: true,
  });

  const actual = when_readingSavedSettingsFile(tempHome);
  const expected = {
    sessionName: "demo",
    extensionSettings: {
      webFetch: { retries: 2, enabled: true },
      webSearch: { enabled: false },
    },
  };

  assert.deepEqual(actual, expected);
});

test("readExtensionSettings GIVEN a stored extension block WHEN reading THEN only that extension settings object is returned", (t) => {
  const tempHome = given_tempHome(t);
  given_savedSettingsFile(tempHome, {
    extensionSettings: {
      subagent: {
        enabled: false,
        maxParallel: 7,
        sources: ["~/.pi/agent/agents"],
      },
      webFetch: { enabled: true },
    },
  });

  const actual = readExtensionSettings<{
    enabled: boolean;
    maxParallel: number;
    sources: string[];
  }>("subagent");
  const expected = {
    enabled: false,
    maxParallel: 7,
    sources: ["~/.pi/agent/agents"],
  };

  assert.deepEqual(actual, expected);
});

test("loadEnabledSettings GIVEN malformed settings file WHEN loading THEN defaults are returned", (t) => {
  const tempHome = given_tempHome(t);
  const settingsPath = path.join(tempHome, ".pi", "agent", "settings.json");
  fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
  fs.writeFileSync(settingsPath, "{not-json", "utf8");

  const actual = loadEnabledSettings("webFetch", { enabled: true });
  const expected = { enabled: true };

  assert.deepEqual(actual, expected);
});

test("loadEnabledSettings GIVEN persisted enabled flag WHEN loading THEN stored boolean overrides defaults", (t) => {
  const tempHome = given_tempHome(t);
  given_savedSettingsFile(tempHome, {
    extensionSettings: {
      webFetch: { enabled: false },
    },
  });

  const actual = loadEnabledSettings("webFetch", { enabled: true });
  const expected = { enabled: false };

  assert.deepEqual(actual, expected);
});
