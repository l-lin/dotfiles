import assert from "node:assert/strict";
import test from "node:test";
import {
  disableSandbox,
  ensureSandboxActive,
  type SandboxRuntimeState,
} from "./activation.js";

function given_runtimeState(
  overrides: Partial<SandboxRuntimeState> = {},
): SandboxRuntimeState {
  return {
    enabled: false,
    initialized: false,
    ...overrides,
  };
}

test("ensureSandboxActive GIVEN extension setting disabled WHEN applying session state THEN initialization is skipped and the sandbox stays inactive", async () => {
  const state = given_runtimeState({ enabled: true, initialized: true });
  let initializeCalls = 0;
  let resetCalls = 0;
  const emittedStates: boolean[] = [];

  const actual = await ensureSandboxActive({
    state,
    settingsEnabled: false,
    noSandbox: false,
    platform: "darwin",
    cwd: process.cwd(),
    loadConfig() {
      throw new Error("Expected config loading to be skipped");
    },
    async initialize() {
      initializeCalls += 1;
    },
    async reset() {
      resetCalls += 1;
    },
    emitStateChanged(enabled) {
      emittedStates.push(enabled);
    },
  });

  assert.equal(initializeCalls, 0);
  assert.equal(resetCalls, 1);
  assert.deepEqual(state, { enabled: false, initialized: false });
  assert.deepEqual(emittedStates, [false]);
  assert.deepEqual(actual, {
    message: "Sandbox disabled via extension setting",
    type: "info",
  });
});

test("ensureSandboxActive GIVEN enabled settings and supported config WHEN applying session state THEN the runtime is initialized and the sandbox becomes active", async () => {
  const state = given_runtimeState();
  let initializeCalls = 0;
  let resetCalls = 0;
  const emittedStates: boolean[] = [];

  const actual = await ensureSandboxActive({
    state,
    settingsEnabled: true,
    noSandbox: false,
    platform: "darwin",
    cwd: process.cwd(),
    loadConfig() {
      return {
        enabled: true,
        network: { allowedDomains: ["github.com"], deniedDomains: [] },
        filesystem: { allowWrite: ["."], denyRead: [], denyWrite: [] },
      };
    },
    async initialize(config) {
      initializeCalls += 1;
      assert.equal(config.enabled, true);
    },
    async reset() {
      resetCalls += 1;
    },
    emitStateChanged(enabled) {
      emittedStates.push(enabled);
    },
  });

  assert.equal(initializeCalls, 1);
  assert.equal(resetCalls, 0);
  assert.deepEqual(state, { enabled: true, initialized: true });
  assert.deepEqual(emittedStates, [true]);
  assert.equal(actual, undefined);
});

test("ensureSandboxActive GIVEN an initialization failure WHEN applying session state THEN the sandbox stays inactive and an error notification is returned", async () => {
  const state = given_runtimeState();
  const emittedStates: boolean[] = [];

  const actual = await ensureSandboxActive({
    state,
    settingsEnabled: true,
    noSandbox: false,
    platform: "darwin",
    cwd: process.cwd(),
    loadConfig() {
      return {
        enabled: true,
        network: { allowedDomains: ["github.com"], deniedDomains: [] },
        filesystem: { allowWrite: ["."], denyRead: [], denyWrite: [] },
      };
    },
    async initialize() {
      throw new Error("boom");
    },
    async reset() {
      throw new Error("Expected reset to be skipped");
    },
    emitStateChanged(enabled) {
      emittedStates.push(enabled);
    },
  });

  assert.deepEqual(state, { enabled: false, initialized: false });
  assert.deepEqual(emittedStates, []);
  assert.deepEqual(actual, {
    message: "Sandbox initialization failed: boom",
    type: "error",
  });
});

test("disableSandbox GIVEN an active runtime WHEN disabling THEN runtime state is cleared and a disabled event is emitted", async () => {
  const state = given_runtimeState({ enabled: true, initialized: true });
  let resetCalls = 0;
  const emittedStates: boolean[] = [];

  await disableSandbox({
    state,
    async reset() {
      resetCalls += 1;
    },
    emitStateChanged(enabled) {
      emittedStates.push(enabled);
    },
  });

  assert.equal(resetCalls, 1);
  assert.deepEqual(state, { enabled: false, initialized: false });
  assert.deepEqual(emittedStates, [false]);
});
