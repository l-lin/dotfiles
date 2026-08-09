import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import yoloExtension from "./index.js";
import {
  YOLO_SET_DAMAGE_CONTROL_ENABLED_EVENT,
  YOLO_SET_SANDBOX_ENABLED_EVENT,
} from "./events.js";

type RegisteredCommand = {
  description?: string;
  handler: Function;
};

function given_mockPi() {
  const registeredCommands = new Map<string, RegisteredCommand>();
  const emittedEvents: Array<{ event: string; payload: unknown }> = [];

  return {
    pi: {
      registerCommand(name: string, command: RegisteredCommand) {
        registeredCommands.set(name, command);
      },
      events: {
        emit(event: string, payload: unknown) {
          emittedEvents.push({ event, payload });
        },
      },
    },
    registeredCommands,
    emittedEvents,
  };
}

function given_mockContext(cwd: string) {
  const notifications: Array<{ message: string; type?: string }> = [];

  return {
    ctx: {
      cwd,
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
  const tempHome = fs.mkdtempSync(path.join(os.tmpdir(), "yolo-"));

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

function given_savedSettingsFile(tempHome: string, settings: unknown): void {
  const settingsPath = path.join(tempHome, ".pi", "agent", "settings.json");
  fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
  fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + "\n");
}

function when_readingSavedSettingsFile(tempHome: string): unknown {
  const settingsPath = path.join(tempHome, ".pi", "agent", "settings.json");
  return JSON.parse(fs.readFileSync(settingsPath, "utf8"));
}

async function when_runningCommand(
  handler: Function,
  ctx: unknown,
): Promise<void> {
  await handler("", ctx);
}

test("yolo GIVEN sandbox enabled and damage-control disabled WHEN toggled THEN sandbox state wins and both are disabled", async (t) => {
  const tempHome = given_tempHome(t);
  const projectDir = fs.mkdtempSync(path.join(os.tmpdir(), "yolo-project-"));
  t.after(() => fs.rmSync(projectDir, { recursive: true, force: true }));
  given_savedSettingsFile(tempHome, {
    extensionSettings: {
      sandbox: { enabled: true },
      damageControl: { enabled: false },
    },
  });

  const { pi, registeredCommands, emittedEvents } = given_mockPi();
  const { ctx, notifications } = given_mockContext(projectDir);

  yoloExtension(pi as never);

  const command = registeredCommands.get("cmd:yolo-toggle");
  assert.ok(command, "Expected yolo toggle command to be registered");

  await when_runningCommand(command.handler, ctx);

  const actualSettingsFile = when_readingSavedSettingsFile(tempHome) as {
    extensionSettings: {
      sandbox: { enabled: boolean };
      damageControl: { enabled: boolean };
    };
  };

  assert.equal(actualSettingsFile.extensionSettings.sandbox.enabled, false);
  assert.equal(
    actualSettingsFile.extensionSettings.damageControl.enabled,
    false,
  );
  assert.deepEqual(emittedEvents, [
    {
      event: YOLO_SET_SANDBOX_ENABLED_EVENT,
      payload: { enabled: false, cwd: projectDir },
    },
    {
      event: YOLO_SET_DAMAGE_CONTROL_ENABLED_EVENT,
      payload: { enabled: false, cwd: projectDir },
    },
  ]);
  assert.deepEqual(notifications, [
    { message: "Sandbox and damage-control disabled", type: "info" },
  ]);
});

test("yolo GIVEN sandbox disabled and damage-control enabled WHEN toggled THEN sandbox state wins and both are enabled", async (t) => {
  const tempHome = given_tempHome(t);
  const projectDir = fs.mkdtempSync(path.join(os.tmpdir(), "yolo-project-"));
  t.after(() => fs.rmSync(projectDir, { recursive: true, force: true }));
  given_savedSettingsFile(tempHome, {
    extensionSettings: {
      sandbox: { enabled: false },
      damageControl: { enabled: true },
    },
  });

  const { pi, registeredCommands, emittedEvents } = given_mockPi();
  const { ctx, notifications } = given_mockContext(projectDir);

  yoloExtension(pi as never);

  const command = registeredCommands.get("cmd:yolo-toggle");
  assert.ok(command, "Expected yolo toggle command to be registered");

  await when_runningCommand(command.handler, ctx);

  const actualSettingsFile = when_readingSavedSettingsFile(tempHome) as {
    extensionSettings: {
      sandbox: { enabled: boolean };
      damageControl: { enabled: boolean };
    };
  };

  assert.equal(actualSettingsFile.extensionSettings.sandbox.enabled, true);
  assert.equal(
    actualSettingsFile.extensionSettings.damageControl.enabled,
    true,
  );
  assert.deepEqual(emittedEvents, [
    {
      event: YOLO_SET_SANDBOX_ENABLED_EVENT,
      payload: { enabled: true, cwd: projectDir },
    },
    {
      event: YOLO_SET_DAMAGE_CONTROL_ENABLED_EVENT,
      payload: { enabled: true, cwd: projectDir },
    },
  ]);
  assert.deepEqual(notifications, [
    { message: "Sandbox and damage-control enabled", type: "info" },
  ]);
});
