import assert from "node:assert/strict";
import test from "node:test";
import {
  createDefaultConfig,
  getDefaultAllowedUnixSockets,
} from "./default-config.js";

function given_defaultConfig(options?: {
  platform?: NodeJS.Platform;
  tmuxTmpDir?: string;
  uid?: number;
}) {
  return createDefaultConfig(options);
}

test("getDefaultAllowedUnixSockets GIVEN macOS uid WHEN resolving THEN the default tmux socket directory is allowlisted", () => {
  const actual = getDefaultAllowedUnixSockets({
    platform: "darwin",
    uid: 501,
  });
  const expected = ["/private/tmp/tmux-501"];

  assert.deepEqual(actual, expected);
});

test("getDefaultAllowedUnixSockets GIVEN TMUX_TMPDIR WHEN resolving THEN that tmux socket directory is allowlisted", () => {
  const actual = getDefaultAllowedUnixSockets({
    platform: "darwin",
    tmuxTmpDir: "/tmp/custom-tmux",
    uid: 501,
  });
  const expected = ["/tmp/custom-tmux/tmux-501"];

  assert.deepEqual(actual, expected);
});

test("getDefaultAllowedUnixSockets GIVEN non-macOS platform WHEN resolving THEN no Unix sockets are allowlisted", () => {
  const actual = getDefaultAllowedUnixSockets({
    platform: "linux",
    uid: 501,
  });

  assert.deepEqual(actual, []);
});

test("createDefaultConfig GIVEN macOS defaults WHEN building THEN tmux Unix sockets are included in network configuration", () => {
  const actual = given_defaultConfig({
    platform: "darwin",
    uid: 501,
  });
  const expected = ["/private/tmp/tmux-501"];

  assert.deepEqual(actual.network?.allowUnixSockets, expected);
});
