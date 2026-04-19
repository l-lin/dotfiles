import assert from "node:assert/strict";
import test from "node:test";
import {
  DAMAGE_CONTROL_TOGGLE_COMMAND,
  registerDamageControlToggleCommand,
} from "./toggle-command.js";

type RegisteredCommand = {
  description?: string;
  handler: Function;
};

function given_mockPi() {
  const registeredCommands = new Map<string, RegisteredCommand>();

  return {
    pi: {
      registerCommand(name: string, command: RegisteredCommand) {
        registeredCommands.set(name, command);
      },
    },
    registeredCommands,
  };
}

function given_mockContext() {
  const notifications: Array<{ message: string; type?: string }> = [];

  return {
    ctx: {
      cwd: process.cwd(),
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
  handler: Function,
  ctx: unknown,
): Promise<void> {
  await handler("", ctx);
}

test("registerDamageControlToggleCommand GIVEN an enabled setting WHEN toggled THEN it persists the disabled state and notifies the user", async () => {
  const { pi, registeredCommands } = given_mockPi();
  const { ctx, notifications } = given_mockContext();
  const settings = { enabled: true };
  const savedValues: boolean[] = [];
  const appliedValues: boolean[] = [];

  registerDamageControlToggleCommand(pi as never, {
    settings,
    saveEnabled(enabled: boolean) {
      savedValues.push(enabled);
    },
    async applySettingChange(enabled: boolean) {
      appliedValues.push(enabled);
    },
  });

  const command = registeredCommands.get(DAMAGE_CONTROL_TOGGLE_COMMAND);
  assert.ok(command, "Expected damage-control toggle command to be registered");

  await when_runningCommand(command.handler, ctx);

  assert.equal(settings.enabled, false);
  assert.deepEqual(savedValues, [false]);
  assert.deepEqual(appliedValues, [false]);
  assert.deepEqual(notifications, [
    { message: "Damage control disabled", type: "info" },
  ]);
});

test("registerDamageControlToggleCommand GIVEN a custom enable notification WHEN toggled on THEN the custom message is shown", async () => {
  const { pi, registeredCommands } = given_mockPi();
  const { ctx, notifications } = given_mockContext();
  const settings = { enabled: false };

  registerDamageControlToggleCommand(pi as never, {
    settings,
    saveEnabled() {
      return undefined;
    },
    async applySettingChange() {
      return {
        message: "Damage control enabled without rules",
        type: "warning",
      };
    },
  });

  const command = registeredCommands.get(DAMAGE_CONTROL_TOGGLE_COMMAND);
  assert.ok(command, "Expected damage-control toggle command to be registered");

  await when_runningCommand(command.handler, ctx);

  assert.equal(settings.enabled, true);
  assert.deepEqual(notifications, [
    { message: "Damage control enabled without rules", type: "warning" },
  ]);
});

test("registerDamageControlToggleCommand GIVEN a persistence failure WHEN toggled THEN in-memory state stays unchanged", async () => {
  const { pi, registeredCommands } = given_mockPi();
  const { ctx, notifications } = given_mockContext();
  const settings = { enabled: true };
  let applyCalls = 0;

  registerDamageControlToggleCommand(pi as never, {
    settings,
    saveEnabled() {
      throw new Error("boom");
    },
    async applySettingChange() {
      applyCalls += 1;
    },
  });

  const command = registeredCommands.get(DAMAGE_CONTROL_TOGGLE_COMMAND);
  assert.ok(command, "Expected damage-control toggle command to be registered");

  await assert.rejects(() => when_runningCommand(command.handler, ctx), /boom/);

  assert.equal(settings.enabled, true);
  assert.equal(applyCalls, 0);
  assert.deepEqual(notifications, []);
});
