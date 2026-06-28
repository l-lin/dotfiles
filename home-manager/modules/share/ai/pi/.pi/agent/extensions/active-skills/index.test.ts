import assert from "node:assert/strict";
import test from "node:test";

import activeSkillsExtension from "./index.js";
import { ICON_SKILL } from "./types.js";
import { clearSkillWidget } from "./widget.js";

type ExtensionHandler = (event: unknown, ctx: unknown) => unknown;

type SkillHistoryEntry = {
  type: "message";
  message: {
    role: "assistant";
    content: Array<{
      type: "toolCall";
      name: "read";
      arguments: {
        path: string;
      };
    }>;
  };
};

function given_mockPi() {
  const extensionHandlers = new Map<string, ExtensionHandler[]>();

  return {
    pi: {
      on(event: string, handler: ExtensionHandler) {
        const handlers = extensionHandlers.get(event) ?? [];
        handlers.push(handler);
        extensionHandlers.set(event, handlers);
      },
    },
    async when_emittingExtensionEvent(
      event: string,
      payload: unknown,
      ctx: unknown,
    ) {
      for (const handler of extensionHandlers.get(event) ?? []) {
        await handler(payload, ctx);
      }
    },
  };
}

function given_skillPath(skillName: string): string {
  return `/tmp/skills/${skillName}/SKILL.md`;
}

function given_skillReadHistoryEntry(skillName: string): SkillHistoryEntry {
  return {
    type: "message",
    message: {
      role: "assistant",
      content: [
        {
          type: "toolCall",
          name: "read",
          arguments: {
            path: given_skillPath(skillName),
          },
        },
      ],
    },
  };
}

function given_readToolResultEvent(skillName: string) {
  return {
    type: "tool_result",
    toolCallId: `tool-call-${skillName}`,
    toolName: "read",
    input: {
      path: given_skillPath(skillName),
    },
    content: [{ type: "text", text: "loaded" }],
    details: undefined,
    isError: false,
  };
}

function given_extensionContext(options: {
  branchEntries: SkillHistoryEntry[];
  allEntries?: SkillHistoryEntry[];
}) {
  let currentBranchEntries = [...options.branchEntries];
  let currentAllEntries = [...(options.allEntries ?? options.branchEntries)];
  let widgetValue:
    | undefined
    | string[]
    | {
        render(width: number): string[];
      };

  const tui = {
    requestRender() {},
  };
  const theme = {
    fg(_color: string, text: string) {
      return text;
    },
    bold(text: string) {
      return text;
    },
  };

  return {
    ctx: {
      hasUI: true,
      sessionManager: {
        getBranch() {
          return currentBranchEntries;
        },
        getEntries() {
          return currentAllEntries;
        },
      },
      ui: {
        setWidget(
          _key: string,
          value:
            | undefined
            | string[]
            | ((
                tuiArg: typeof tui,
                themeArg: typeof theme,
              ) => { render(width: number): string[] }),
        ) {
          if (typeof value === "function") {
            widgetValue = value(tui, theme);
            return;
          }
          widgetValue = value;
        },
      },
    },
    when_renderingWidget() {
      if (widgetValue === undefined) return undefined;
      if (Array.isArray(widgetValue)) return [...widgetValue];
      return widgetValue.render(120);
    },
    when_switchingToBranch(branchEntries: SkillHistoryEntry[]) {
      currentBranchEntries = [...branchEntries];
    },
  };
}

test("active-skills GIVEN skills on another branch WHEN the session starts THEN it rebuilds from the current branch only", async (t) => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_renderingWidget } = given_extensionContext({
    branchEntries: [given_skillReadHistoryEntry("clarifying-intent")],
    allEntries: [
      given_skillReadHistoryEntry("clarifying-intent"),
      given_skillReadHistoryEntry("clear-writing"),
    ],
  });
  t.after(() => clearSkillWidget(ctx as never));

  activeSkillsExtension(pi as never);

  await when_emittingExtensionEvent(
    "session_start",
    { type: "session_start", reason: "startup" },
    ctx,
  );

  const actual = when_renderingWidget();
  const expected = [`${ICON_SKILL} clarifying-intent`];

  assert.deepEqual(actual, expected);
});

test("active-skills GIVEN a user returns to earlier history WHEN session_tree fires THEN it clears obsolete skills and rebuilds the widget", async (t) => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_renderingWidget, when_switchingToBranch } =
    given_extensionContext({
      branchEntries: [given_skillReadHistoryEntry("clarifying-intent")],
    });
  t.after(() => clearSkillWidget(ctx as never));

  activeSkillsExtension(pi as never);

  await when_emittingExtensionEvent(
    "session_start",
    { type: "session_start", reason: "startup" },
    ctx,
  );
  await when_emittingExtensionEvent(
    "tool_result",
    given_readToolResultEvent("devils-advocate"),
    ctx,
  );

  const actualBeforeTreeNavigation = when_renderingWidget();
  const expectedBeforeTreeNavigation = [
    `${ICON_SKILL} clarifying-intent+devils-advocate`,
  ];
  assert.deepEqual(actualBeforeTreeNavigation, expectedBeforeTreeNavigation);

  when_switchingToBranch([given_skillReadHistoryEntry("clarifying-intent")]);

  await when_emittingExtensionEvent(
    "session_tree",
    { type: "session_tree", newLeafId: "leaf-b", oldLeafId: "leaf-a" },
    ctx,
  );

  const actual = when_renderingWidget();
  const expected = [`${ICON_SKILL} clarifying-intent`];

  assert.deepEqual(actual, expected);
});
