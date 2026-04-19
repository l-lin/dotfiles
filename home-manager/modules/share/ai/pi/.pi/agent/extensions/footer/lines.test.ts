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
  damageControlEnabled?: boolean;
  branch?: string | null;
}) {
  return buildDirectoryLine(
    options?.width ?? 120,
    given_theme() as never,
    given_footerData(options?.branch) as never,
    {
      sandboxEnabled: options?.sandboxEnabled ?? false,
      damageControlEnabled: options?.damageControlEnabled ?? false,
    },
  );
}

test("buildDirectoryLine GIVEN sandbox enabled WHEN rendering THEN it shows the enabled sandbox icon before the cwd icon", () => {
  const actual = when_buildingDirectoryLine({ sandboxEnabled: true });
  const expected = `<dim>${ICONS["sandbox-enabled"]}</dim>`;

  assert.ok(actual.includes(expected));
  assert.ok(
    actual.includes(`<error>${ICONS["damage-control-disabled"]}</error>`),
  );
  assert.ok(actual.includes(ICONS["cwd"]));
  assert.ok(!actual.includes(ICONS["sandbox-disabled"]));
});

test("buildDirectoryLine GIVEN damage control enabled WHEN rendering THEN it shows the enabled damage-control icon beside the sandbox icon", () => {
  const actual = when_buildingDirectoryLine({ damageControlEnabled: true });
  const expected = `<dim>${ICONS["damage-control-enabled"]}</dim>`;

  assert.ok(actual.includes(`<error>${ICONS["sandbox-disabled"]}</error>`));
  assert.ok(actual.includes(expected));
  assert.ok(actual.includes(ICONS["cwd"]));
  assert.ok(!actual.includes(ICONS["damage-control-disabled"]));
});

test("buildDirectoryLine GIVEN damage control disabled WHEN rendering THEN it shows the disabled damage-control icon in red", () => {
  const actual = when_buildingDirectoryLine({ damageControlEnabled: false });
  const expected = `<error>${ICONS["damage-control-disabled"]}</error>`;

  assert.ok(actual.includes(expected));
  assert.ok(actual.includes(ICONS["cwd"]));
  assert.ok(!actual.includes(ICONS["damage-control-enabled"]));
});
