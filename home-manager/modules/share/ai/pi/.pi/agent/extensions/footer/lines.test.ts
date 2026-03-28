import assert from "node:assert/strict";
import test from "node:test";
import { buildDirectoryLine } from "./lines.js";
import { ICONS } from "./constants.js";

function given_theme() {
  return {
    fg(color: string, text: string) {
      return `<${color}>${text}</${color}>`;
    },
  };
}

function given_footerData(branch: string | null = "main") {
  return {
    getGitBranch() {
      return branch;
    },
  };
}

function when_buildingDirectoryLine(options?: {
  width?: number;
  sandboxEnabled?: boolean;
  branch?: string | null;
}) {
  return buildDirectoryLine(
    options?.width ?? 120,
    given_theme() as never,
    given_footerData(options?.branch) as never,
    options?.sandboxEnabled ?? false,
  );
}

test("buildDirectoryLine GIVEN sandbox enabled WHEN rendering THEN it shows the enabled sandbox icon before the cwd icon", () => {
  const actual = when_buildingDirectoryLine({ sandboxEnabled: true });
  const expected = `<dim>${ICONS["sandbox-enabled"]}</dim>`;

  assert.ok(actual.includes(expected));
  assert.ok(actual.includes(ICONS["cwd"]));
  assert.ok(!actual.includes(ICONS["sandbox-disabled"]));
});

test("buildDirectoryLine GIVEN sandbox disabled WHEN rendering THEN it shows the disabled sandbox icon in red", () => {
  const actual = when_buildingDirectoryLine({ sandboxEnabled: false });
  const expected = `<error>${ICONS["sandbox-disabled"]}</error>`;

  assert.ok(actual.includes(expected));
  assert.ok(actual.includes(ICONS["cwd"]));
  assert.ok(!actual.includes(ICONS["sandbox-enabled"]));
});
