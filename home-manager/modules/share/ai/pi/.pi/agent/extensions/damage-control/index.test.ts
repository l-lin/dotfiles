import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import damageControlExtension from "./index.js";
import { DAMAGE_CONTROL_TOGGLE_COMMAND } from "./toggle-command.js";

const RULES_YAML = `bashToolPatterns:\n  - pattern: "^rm"\n    reason: "No rm"\n`;

type RegisteredCommand = {
  description?: string;
  handler: Function;
};

function given_mockPi() {
  const sessionStartHandlers: Function[] = [];
  const toolCallHandlers: Function[] = [];
  const registeredCommands = new Map<string, RegisteredCommand>();
  const emittedEvents: Array<{ event: string; payload: unknown }> = [];

  return {
    pi: {
      on(event: string, handler: Function) {
        if (event === "session_start") {
          sessionStartHandlers.push(handler);
        }

        if (event === "tool_call") {
          toolCallHandlers.push(handler);
        }
      },
      registerCommand(name: string, command: RegisteredCommand) {
        registeredCommands.set(name, command);
      },
      appendEntry() {
        return undefined;
      },
      events: {
        emit(event: string, payload: unknown) {
          emittedEvents.push({ event, payload });
        },
      },
    },
    registeredCommands,
    emittedEvents,
    async when_startingSession(ctx: unknown) {
      for (const handler of sessionStartHandlers) {
        await handler({}, ctx);
      }
    },
    async when_handlingToolCall(event: unknown, ctx: unknown) {
      let actual;

      for (const handler of toolCallHandlers) {
        actual = await handler(event, ctx);
      }

      return actual;
    },
  };
}

function given_runtimeContext(cwd: string) {
  const notifications: Array<{ message: string; type?: string }> = [];
  let abortCount = 0;

  return {
    ctx: {
      cwd,
      ui: {
        notify(message: string, type?: string) {
          notifications.push({ message, type });
        },
        async confirm() {
          throw new Error("Did not expect a confirmation prompt");
        },
      },
      abort() {
        abortCount += 1;
      },
    },
    notifications,
    when_gettingAbortCount() {
      return abortCount;
    },
  };
}

function given_tempHome(t: test.TestContext): string {
  const previousHome = process.env.HOME;
  const previousXdgConfigHome = process.env.XDG_CONFIG_HOME;
  const tempHome = fs.mkdtempSync(path.join(os.tmpdir(), "damage-control-"));

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

function given_projectRulesFile(projectDir: string): string {
  const rulesPath = path.join(
    projectDir,
    ".pi",
    "agent",
    "damage-control-rules.yml",
  );
  fs.mkdirSync(path.dirname(rulesPath), { recursive: true });
  fs.writeFileSync(rulesPath, RULES_YAML, "utf8");
  return rulesPath;
}

function given_savedSettingsFile(tempHome: string, settings: unknown): string {
  const settingsPath = path.join(tempHome, ".pi", "agent", "settings.json");
  fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
  fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + "\n");
  return settingsPath;
}

function given_bashToolCall(command: string) {
  return {
    type: "tool_call",
    toolCallId: "tool-call-1",
    toolName: "bash",
    input: { command },
  };
}

async function when_runningCommand(
  handler: Function,
  ctx: unknown,
): Promise<void> {
  await handler("", ctx);
}

test("damage-control GIVEN an enabled session WHEN toggled off THEN matching commands stop being blocked in the current session", async (t) => {
  given_tempHome(t);
  const projectDir = fs.mkdtempSync(
    path.join(os.tmpdir(), "damage-control-project-"),
  );
  t.after(() => fs.rmSync(projectDir, { recursive: true, force: true }));
  given_projectRulesFile(projectDir);

  const {
    pi,
    registeredCommands,
    emittedEvents,
    when_startingSession,
    when_handlingToolCall,
  } = given_mockPi();
  const { ctx, notifications, when_gettingAbortCount } =
    given_runtimeContext(projectDir);

  damageControlExtension(pi as never);
  await when_startingSession(ctx as never);

  const blockedBeforeToggle = await when_handlingToolCall(
    given_bashToolCall("rm -rf build"),
    ctx as never,
  );
  assert.equal(blockedBeforeToggle?.block, true);
  assert.equal(when_gettingAbortCount(), 1);

  const command = registeredCommands.get(DAMAGE_CONTROL_TOGGLE_COMMAND);
  assert.ok(command, "Expected damage-control toggle command to be registered");

  await when_runningCommand(command.handler, ctx);

  const allowedAfterToggle = await when_handlingToolCall(
    given_bashToolCall("rm -rf build"),
    ctx as never,
  );

  assert.equal(allowedAfterToggle?.block, false);
  assert.equal(when_gettingAbortCount(), 1);
  assert.deepEqual(emittedEvents, [
    { event: "damage-control:state-changed", payload: true },
    { event: "damage-control:state-changed", payload: false },
  ]);
  assert.deepEqual(notifications, [
    { message: " BLOCKED: bash due to No rm", type: undefined },
    { message: "Damage control disabled", type: "info" },
  ]);
});

test("damage-control GIVEN a persisted disabled setting WHEN toggled on THEN matching commands are blocked in the current session", async (t) => {
  const tempHome = given_tempHome(t);
  const projectDir = fs.mkdtempSync(
    path.join(os.tmpdir(), "damage-control-project-"),
  );
  t.after(() => fs.rmSync(projectDir, { recursive: true, force: true }));
  given_projectRulesFile(projectDir);
  given_savedSettingsFile(tempHome, {
    extensionSettings: {
      damageControl: { enabled: false },
    },
  });

  const {
    pi,
    registeredCommands,
    emittedEvents,
    when_startingSession,
    when_handlingToolCall,
  } = given_mockPi();
  const { ctx, notifications, when_gettingAbortCount } =
    given_runtimeContext(projectDir);

  damageControlExtension(pi as never);
  await when_startingSession(ctx as never);

  const allowedBeforeToggle = await when_handlingToolCall(
    given_bashToolCall("rm -rf build"),
    ctx as never,
  );
  assert.equal(allowedBeforeToggle?.block, false);
  assert.equal(when_gettingAbortCount(), 0);

  const command = registeredCommands.get(DAMAGE_CONTROL_TOGGLE_COMMAND);
  assert.ok(command, "Expected damage-control toggle command to be registered");

  await when_runningCommand(command.handler, ctx);

  const blockedAfterToggle = await when_handlingToolCall(
    given_bashToolCall("rm -rf build"),
    ctx as never,
  );

  assert.equal(blockedAfterToggle?.block, true);
  assert.equal(when_gettingAbortCount(), 1);
  assert.deepEqual(emittedEvents, [
    { event: "damage-control:state-changed", payload: false },
    { event: "damage-control:state-changed", payload: true },
  ]);
  assert.deepEqual(notifications, [
    { message: "Damage control enabled", type: "info" },
    { message: " BLOCKED: bash due to No rm", type: undefined },
  ]);
});
