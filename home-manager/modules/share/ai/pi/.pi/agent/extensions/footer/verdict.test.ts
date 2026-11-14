import assert from "node:assert/strict";
import { test } from "node:test";
import footer from "./index.js";
import { buildToolIcons } from "./data.js";
import { TOOL_ICONS } from "./constants.js";

test("GIVEN verdict runtime state WHEN footer icons render THEN the shield matches the active state", () => {
  const colors: string[] = [];
  const theme: any = {
    fg: (color: string, text: string) => {
      colors.push(color);
      return text;
    },
  };
  const actual = [
    buildToolIcons(theme, true),
    buildToolIcons(theme, false),
    buildToolIcons(theme),
  ];
  const expected = TOOL_ICONS.verdict;
  assert.equal(actual[0].split(" ").at(-1), expected.enabled);
  assert.equal(actual[1].split(" ").at(-1), expected.disabled);
  assert.equal(actual[2].includes(expected.enabled), false);
  assert.equal(actual[2].includes(expected.disabled), false);
  assert.equal(
    colors.every((color) => color === "dim"),
    true,
  );
});

test("GIVEN footer and verdict events WHEN runtime state changes THEN footer requests a new render", async () => {
  const subscribers = new Map<string, (data: unknown) => void>();
  const handlers: Record<string, (event: unknown, ctx: any) => void> = {};
  let requested = 0;
  let component: any;
  let statusRequests = 0;
  const ctx: any = {
    hasUI: true,
    getContextUsage: () => null,
    model: undefined,
    sessionManager: { getEntries: () => [] },
    ui: {
      setFooter(factory: any) {
        component = factory(
          {
            requestRender: () => {
              requested++;
            },
          },
          { fg: (_color: string, text: string) => text },
          {
            getGitBranch: () => undefined,
            getExtensionStatuses: () => new Map(),
          },
        );
      },
    },
  };
  footer({
    events: {
      on: (name: string, handler: (data: unknown) => void) =>
        subscribers.set(name, handler),
      emit: (name: string) => {
        if (name === "verdict:request-status") statusRequests++;
      },
    },
    on: (name: string, handler: any) => {
      handlers[name] = handler;
    },
    getThinkingLevel: () => "off",
  } as any);
  handlers.session_start({}, ctx);
  await import("./lines.js");
  await new Promise<void>((resolve) => setImmediate(resolve));
  subscribers.get("verdict:changed")!({ enabled: true });
  const actual = component.render(200)[0];
  const expected = TOOL_ICONS.verdict.enabled;
  assert.ok(actual.includes(expected));
  assert.equal(statusRequests, 1);
  const previous = requested;
  subscribers.get("verdict:changed")!({ enabled: false });
  assert.ok(requested > previous);
  assert.ok(component.render(200)[0].includes(TOOL_ICONS.verdict.disabled));
  subscribers.get("verdict:changed")!({ enabled: "invalid" });
  assert.ok(component.render(200)[0].includes(TOOL_ICONS.verdict.disabled));
  subscribers.get("verdict:changed")!({ enabled: undefined });
  assert.equal(
    component.render(200)[0].includes(TOOL_ICONS.verdict.disabled),
    false,
  );
});
