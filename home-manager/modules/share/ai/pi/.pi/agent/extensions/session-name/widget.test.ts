import assert from "node:assert/strict";
import test from "node:test";
import { stripVTControlCharacters } from "node:util";
import type {
  ExtensionAPI,
  ExtensionContext,
  Theme,
} from "@earendil-works/pi-coding-agent";
import type { Component, TUI } from "@earendil-works/pi-tui";
import { visibleWidth } from "@earendil-works/pi-tui";
import sessionNameExtension from "./index.js";
import { buildSessionNameLine } from "./widget.js";

const theme = {
  fg: (_color: string, value: string) => value,
  bg: (_color: string, value: string) => value,
} as Theme;

for (const name of [undefined, "", " \t\r\n "]) {
  test(`GIVEN name ${JSON.stringify(name)} WHEN formatted THEN the name line is absent`, () => {
    const actual = buildSessionNameLine(80, theme, name);
    const expected = null;
    assert.equal(actual, expected);
  });
}

test("GIVEN a name with line breaks WHEN formatted THEN the padded label occupies one line", () => {
  const actual = buildSessionNameLine(
    80,
    theme,
    "  feature/test\nnext\tpart\rend  ",
  );
  const expected = "  feature/test next part end ";
  assert.equal(actual, expected);
});

for (const width of [0, 1, 2, 8, 20]) {
  test(`GIVEN a long Unicode name WHEN formatted at width ${width} THEN it fits the terminal`, () => {
    const line = buildSessionNameLine(
      width,
      theme,
      "修正 😀 a long session name",
    )!;
    const actual = visibleWidth(line) <= width;
    const expected = true;
    assert.equal(actual, expected);
    if (width > 1) {
      const actual = stripVTControlCharacters(line).endsWith("… ");
      const expected = true;
      assert.equal(actual, expected);
    }
  });
}

test("GIVEN a session name WHEN formatted THEN only the padded label receives the theme background", () => {
  const colors: unknown[] = [];
  const given_theme = {
    fg: (color: string, value: string) => {
      colors.push(["fg", color]);
      return value;
    },
    bg: (color: string, value: string) => {
      colors.push(["bg", color, value]);
      return value;
    },
  } as Theme;
  buildSessionNameLine(80, given_theme, "Named session");
  const actual = colors;
  const expected = [
    ["fg", "text"],
    ["bg", "userMessageBg", "  Named session "],
  ];
  assert.deepEqual(actual, expected);
});

async function given_session_widget(name?: string, hasUI = true) {
  const handlers = new Map<
    string,
    (event: unknown, ctx: ExtensionContext) => unknown
  >();
  let widget: Component | undefined;
  let placement: string | undefined;
  let updates = 0;
  let sessionName = name;
  const tui = {} as TUI;
  const ctx = {
    hasUI,
    sessionManager: {
      getSessionName: () => sessionName,
    },
    ui: {
      setWidget(
        key: string,
        factory?: (tui: TUI, theme: Theme) => Component,
        options?: { placement: string },
      ) {
        assert.equal(key, "session-name");
        updates += 1;
        placement = options?.placement;
        widget = factory?.(tui, theme);
      },
    },
  } as unknown as ExtensionContext;
  sessionNameExtension({
    registerCommand() {},
    on(
      event: string,
      handler: (event: unknown, ctx: ExtensionContext) => unknown,
    ) {
      handlers.set(event, handler);
    },
    exec: async () => ({
      stdout: "feature/auto",
      code: 0,
      killed: false,
      truncated: false,
    }),
    setSessionName(value: string) {
      sessionName = value;
      handlers.get("session_info_changed")!({}, ctx);
    },
  } as unknown as ExtensionAPI);
  await handlers.get("session_start")!({ reason: "reload" }, ctx);
  return {
    when_rendering: () => ({
      widget: widget?.render(160) ?? [],
      placement,
      updates,
    }),
    when_renaming(value?: string, emitEvent = true) {
      sessionName = value;
      if (emitEvent) handlers.get("session_info_changed")!({}, ctx);
    },
    async when_starting(value?: string, reason = "reload") {
      sessionName = value;
      await handlers.get("session_start")!({ reason }, ctx);
    },
  };
}

test("GIVEN a named session without the footer extension WHEN rendered THEN its label appears above the editor", async () => {
  const session = await given_session_widget("feature/test");
  const actual = session.when_rendering();
  const expected = {
    widget: ["  feature/test "],
    placement: "aboveEditor",
    updates: 1,
  };
  assert.deepEqual(actual, expected);
});

test("GIVEN an unnamed session WHEN the branch sets its name THEN the widget shows the branch", async () => {
  const session = await given_session_widget();
  await session.when_starting(undefined, "new");
  const actual = session.when_rendering().widget;
  const expected = ["  feature/auto "];
  assert.deepEqual(actual, expected);
});

for (const name of [undefined, " \t\n "]) {
  test(`GIVEN name ${JSON.stringify(name)} WHEN rendered THEN no widget row appears`, async () => {
    const session = await given_session_widget(name);
    const actual = session.when_rendering().widget;
    const expected: string[] = [];
    assert.deepEqual(actual, expected);
  });
}

test("GIVEN a session label WHEN renamed or cleared THEN the widget updates immediately", async () => {
  const session = await given_session_widget("Old name");
  session.when_renaming("New name");
  const renamed = session.when_rendering();
  session.when_renaming();
  const cleared = session.when_rendering();
  const actual = {
    renamed: renamed.widget,
    cleared: cleared.widget,
    updates: cleared.updates,
  };
  const expected = { renamed: ["  New name "], cleared: [], updates: 3 };
  assert.deepEqual(actual, expected);
});

for (const name of [undefined, "Old name"]) {
  test(`GIVEN name ${JSON.stringify(name)} WHEN renamed without a session event THEN rendering uses the current name`, async () => {
    // GIVEN
    const session = await given_session_widget(name);

    // WHEN
    session.when_renaming("Custom name", false);
    const renamed = session.when_rendering();
    session.when_renaming(undefined, false);
    const cleared = session.when_rendering();
    session.when_renaming("Other custom name", false);
    const restored = session.when_rendering();

    // THEN
    const actual = {
      renamed: renamed.widget,
      cleared: cleared.widget,
      restored: restored.widget,
      updates: restored.updates,
    };
    const expected = {
      renamed: ["  Custom name "],
      cleared: [],
      restored: ["  Other custom name "],
      updates: 1,
    };
    assert.deepEqual(actual, expected);
  });
}

test("GIVEN a session label WHEN another session starts THEN the widget uses its name", async () => {
  const session = await given_session_widget("Old session");
  await session.when_starting("Other session");
  const actual = session.when_rendering().widget;
  const expected = ["  Other session "];
  assert.deepEqual(actual, expected);
});

test("GIVEN no UI WHEN the session name changes THEN no widget is installed", async () => {
  const session = await given_session_widget("Named session", false);
  session.when_renaming("Other name");
  const actual = session.when_rendering();
  const expected = { widget: [], placement: undefined, updates: 0 };
  assert.deepEqual(actual, expected);
});
