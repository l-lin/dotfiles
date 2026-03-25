import assert from "node:assert/strict";
import test from "node:test";
import { registerEnabledToggleCommand } from "./index.js";

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
      registerCommand(name: string, options: { description?: string; handler: Function }) {
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

async function when_runningCommand(
  commandHandler: Function,
  ctx: unknown,
): Promise<void> {
  await commandHandler("", ctx);
}

test("registerEnabledToggleCommand GIVEN a tool-backed extension WHEN toggled THEN it persists state, updates active tools, and emits a change event", async () => {
  const { pi, registeredCommands, emittedEvents, setActiveToolsCalls } =
    given_mockPi(["read", "web-fetch"]);
  const { ctx, notifications } = given_mockContext();
  const settings = { enabled: true };
  const savedValues: boolean[] = [];

  registerEnabledToggleCommand(pi as never, {
    description: "Toggle web-fetch tool on/off",
    settings,
    saveEnabled(enabled: boolean) {
      savedValues.push(enabled);
    },
    toolName: "web-fetch",
  });

  const command = registeredCommands.get("cmd:web-fetch-toggle");
  assert.ok(command, "Expected toggle command to be registered");

  await when_runningCommand(command.handler, ctx);

  assert.equal(settings.enabled, false);
  assert.deepEqual(savedValues, [false]);
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

test("registerEnabledToggleCommand GIVEN a command-only extension WHEN toggled THEN it persists state without touching active tools", async () => {
  const { pi, registeredCommands, emittedEvents, setActiveToolsCalls } =
    given_mockPi(["read"]);
  const { ctx, notifications } = given_mockContext();
  const settings = { enabled: true };
  const savedValues: boolean[] = [];

  registerEnabledToggleCommand(pi as never, {
    toolName: "lsp-diagnostics",
    description: "Toggle LSP extension on/off",
    settings,
    saveEnabled(enabled: boolean) {
      savedValues.push(enabled);
    },
  });

  const command = registeredCommands.get("cmd:lsp-diagnostics-toggle");
  assert.ok(command, "Expected toggle command to be registered");

  await when_runningCommand(command.handler, ctx);

  assert.equal(settings.enabled, false);
  assert.deepEqual(savedValues, [false]);
  assert.deepEqual(setActiveToolsCalls, [["read"]]);
  assert.deepEqual(emittedEvents, [
    {
      event: "custom-tool:changed",
      payload: { tool: "lsp-diagnostics", enabled: false },
    },
  ]);
  assert.deepEqual(notifications, [
    { message: "lsp-diagnostics disabled", type: "info" },
  ]);
});
