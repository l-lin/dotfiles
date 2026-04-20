import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import damageControlExtension from "./index.js";
import { DAMAGE_CONTROL_TOGGLE_COMMAND } from "./toggle-command.js";

const DEFAULT_RULES_YAML = `bashToolPatterns:\n  - pattern: "^rm"\n    reason: "No rm"\n`;
const READ_ONLY_RULES_YAML = `readOnlyPaths:\n  - "package-lock.json"\n`;

type RegisteredCommand = {
  description?: string;
  handler: Function;
};

type ConfirmCall = {
  title: string;
  message: string;
  options?: unknown;
};

type Notification = {
  message: string;
  type?: string;
};

type AppendedEntry = {
  customType: string;
  data: unknown;
};

function given_mockPi() {
  const sessionStartHandlers: Function[] = [];
  const toolCallHandlers: Function[] = [];
  const registeredCommands = new Map<string, RegisteredCommand>();
  const emittedEvents: Array<{ event: string; payload: unknown }> = [];
  const appendedEntries: AppendedEntry[] = [];

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
      appendEntry(customType: string, data: unknown) {
        appendedEntries.push({ customType, data });
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
    appendedEntries,
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

function given_runtimeContext(
  cwd: string,
  options: {
    confirmResults?: boolean[];
    hasUI?: boolean;
  } = {},
) {
  const notifications: Notification[] = [];
  const confirmCalls: ConfirmCall[] = [];
  const confirmResults = [...(options.confirmResults ?? [])];
  let abortCount = 0;

  return {
    ctx: {
      cwd,
      hasUI: options.hasUI ?? true,
      ui: {
        notify(message: string, type?: string) {
          notifications.push({ message, type });
        },
        async confirm(
          title: string,
          message: string,
          confirmOptions?: unknown,
        ) {
          confirmCalls.push({ title, message, options: confirmOptions });
          return confirmResults.shift() ?? false;
        },
      },
      abort() {
        abortCount += 1;
      },
    },
    notifications,
    confirmCalls,
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

function given_projectRulesFile(
  projectDir: string,
  content: string = DEFAULT_RULES_YAML,
): string {
  const rulesPath = path.join(
    projectDir,
    ".pi",
    "agent",
    "damage-control-rules.yml",
  );
  fs.mkdirSync(path.dirname(rulesPath), { recursive: true });
  fs.writeFileSync(rulesPath, content, "utf8");
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

function given_writeToolCall(targetPath: string) {
  return {
    type: "tool_call",
    toolCallId: "tool-call-1",
    toolName: "write",
    input: {
      path: targetPath,
      content: "updated file",
    },
  };
}

async function when_runningCommand(
  handler: Function,
  ctx: unknown,
): Promise<void> {
  await handler("", ctx);
}

test("damage-control GIVEN a matching bash rule WHEN the user allows it THEN it asks first and lets the command run", async (t) => {
  given_tempHome(t);
  const projectDir = fs.mkdtempSync(
    path.join(os.tmpdir(), "damage-control-project-"),
  );
  t.after(() => fs.rmSync(projectDir, { recursive: true, force: true }));
  given_projectRulesFile(projectDir);

  const { pi, appendedEntries, when_startingSession, when_handlingToolCall } =
    given_mockPi();
  const { ctx, confirmCalls, notifications, when_gettingAbortCount } =
    given_runtimeContext(projectDir, { confirmResults: [true] });

  damageControlExtension(pi as never);
  await when_startingSession(ctx as never);

  const actual = await when_handlingToolCall(
    given_bashToolCall("rm -rf build"),
    ctx as never,
  );
  const expected = { block: false };

  assert.deepEqual(actual, expected);
  assert.equal(when_gettingAbortCount(), 0);
  assert.equal(confirmCalls.length, 1);
  assert.match(confirmCalls[0]?.message ?? "", /No rm/);
  assert.match(confirmCalls[0]?.message ?? "", /rm -rf build/);
  assert.deepEqual(notifications, []);
  assert.deepEqual(appendedEntries, [
    {
      customType: "damage-control-log",
      data: {
        tool: "bash",
        input: { command: "rm -rf build" },
        rule: "No rm",
        action: "confirmed_by_user",
      },
    },
  ]);
});

test("damage-control GIVEN a matching read-only path rule WHEN the user denies permission THEN it asks first and blocks the write", async (t) => {
  given_tempHome(t);
  const projectDir = fs.mkdtempSync(
    path.join(os.tmpdir(), "damage-control-project-"),
  );
  t.after(() => fs.rmSync(projectDir, { recursive: true, force: true }));
  given_projectRulesFile(projectDir, READ_ONLY_RULES_YAML);

  const { pi, appendedEntries, when_startingSession, when_handlingToolCall } =
    given_mockPi();
  const { ctx, confirmCalls, notifications, when_gettingAbortCount } =
    given_runtimeContext(projectDir, { confirmResults: [false] });

  damageControlExtension(pi as never);
  await when_startingSession(ctx as never);

  const actual = await when_handlingToolCall(
    given_writeToolCall("package-lock.json"),
    ctx as never,
  );

  assert.equal(actual?.block, true);
  assert.match(actual?.reason ?? "", /User denied/);
  assert.equal(when_gettingAbortCount(), 1);
  assert.equal(confirmCalls.length, 1);
  assert.match(confirmCalls[0]?.message ?? "", /package-lock\.json/);
  assert.deepEqual(notifications, [
    {
      message:
        "⚠️ Violation Blocked: Modification of read-only path restricted: package-lock.json",
      type: undefined,
    },
  ]);
  assert.deepEqual(appendedEntries, [
    {
      customType: "damage-control-log",
      data: {
        tool: "write",
        input: {
          path: "package-lock.json",
          content: "updated file",
        },
        rule: "Modification of read-only path restricted: package-lock.json",
        action: "blocked_by_user",
      },
    },
  ]);
});

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
  const { ctx, confirmCalls, when_gettingAbortCount } = given_runtimeContext(
    projectDir,
    { confirmResults: [false] },
  );

  damageControlExtension(pi as never);
  await when_startingSession(ctx as never);

  const blockedBeforeToggle = await when_handlingToolCall(
    given_bashToolCall("rm -rf build"),
    ctx as never,
  );
  assert.equal(blockedBeforeToggle?.block, true);
  assert.equal(when_gettingAbortCount(), 1);
  assert.equal(confirmCalls.length, 1);

  const command = registeredCommands.get(DAMAGE_CONTROL_TOGGLE_COMMAND);
  assert.ok(command, "Expected damage-control toggle command to be registered");

  await when_runningCommand(command.handler, ctx);

  const allowedAfterToggle = await when_handlingToolCall(
    given_bashToolCall("rm -rf build"),
    ctx as never,
  );

  assert.equal(allowedAfterToggle?.block, false);
  assert.equal(when_gettingAbortCount(), 1);
  assert.equal(confirmCalls.length, 1);
  assert.deepEqual(emittedEvents, [
    { event: "damage-control:state-changed", payload: true },
    { event: "damage-control:state-changed", payload: false },
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
  const { ctx, confirmCalls, when_gettingAbortCount } = given_runtimeContext(
    projectDir,
    { confirmResults: [false] },
  );

  damageControlExtension(pi as never);
  await when_startingSession(ctx as never);

  const allowedBeforeToggle = await when_handlingToolCall(
    given_bashToolCall("rm -rf build"),
    ctx as never,
  );
  assert.equal(allowedBeforeToggle?.block, false);
  assert.equal(when_gettingAbortCount(), 0);
  assert.equal(confirmCalls.length, 0);

  const command = registeredCommands.get(DAMAGE_CONTROL_TOGGLE_COMMAND);
  assert.ok(command, "Expected damage-control toggle command to be registered");

  await when_runningCommand(command.handler, ctx);

  const blockedAfterToggle = await when_handlingToolCall(
    given_bashToolCall("rm -rf build"),
    ctx as never,
  );

  assert.equal(blockedAfterToggle?.block, true);
  assert.equal(when_gettingAbortCount(), 1);
  assert.equal(confirmCalls.length, 1);
  assert.deepEqual(emittedEvents, [
    { event: "damage-control:state-changed", payload: false },
    { event: "damage-control:state-changed", payload: true },
  ]);
});
