import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {
  loadSandboxEnabledSettings,
  saveSandboxEnabledSettings,
} from "./settings.js";

function given_tempHome(t: test.TestContext): string {
  const previousHome = process.env.HOME;
  const previousXdgConfigHome = process.env.XDG_CONFIG_HOME;
  const tempHome = fs.mkdtempSync(path.join(os.tmpdir(), "sandbox-settings-"));

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

function when_readingSavedSettingsFile(tempHome: string): unknown {
  const settingsPath = path.join(tempHome, ".pi", "agent", "settings.json");
  return JSON.parse(fs.readFileSync(settingsPath, "utf8"));
}

test("loadSandboxEnabledSettings GIVEN no settings file WHEN loading THEN enabled defaults to true", (t) => {
  given_tempHome(t);

  const actual = loadSandboxEnabledSettings();
  const expected = { enabled: true };

  assert.deepEqual(actual, expected);
});

test("loadSandboxEnabledSettings GIVEN a persisted disabled flag WHEN loading THEN the stored boolean is returned", (t) => {
  const tempHome = given_tempHome(t);
  given_savedSettingsFile(tempHome, {
    extensionSettings: {
      sandbox: { enabled: false },
    },
  });

  const actual = loadSandboxEnabledSettings();
  const expected = { enabled: false };

  assert.deepEqual(actual, expected);
});

test("saveSandboxEnabledSettings GIVEN sibling extension settings WHEN saving THEN the sandbox enabled flag is updated without losing other keys", (t) => {
  const tempHome = given_tempHome(t);
  given_savedSettingsFile(tempHome, {
    sessionName: "demo",
    extensionSettings: {
      sandbox: { mode: "strict" },
      webFetch: { enabled: false },
    },
  });

  saveSandboxEnabledSettings(true);

  const actual = when_readingSavedSettingsFile(tempHome);
  const expected = {
    sessionName: "demo",
    extensionSettings: {
      sandbox: { mode: "strict", enabled: true },
      webFetch: { enabled: false },
    },
  };

  assert.deepEqual(actual, expected);
});
