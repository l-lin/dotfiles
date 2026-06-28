import assert from "node:assert/strict";
import test from "node:test";
import footerExtension from "./index.js";
import { ICONS } from "./constants.js";

function given_mockPi() {
  const sessionStartHandlers: Function[] = [];
  const eventHandlers = new Map<string, Function[]>();

  return {
    pi: {
      on(event: string, handler: Function) {
        if (event === "session_start") {
          sessionStartHandlers.push(handler);
        }
      },
      events: {
        on(event: string, handler: Function) {
          const handlers = eventHandlers.get(event) ?? [];
          handlers.push(handler);
          eventHandlers.set(event, handlers);
        },
      },
      getThinkingLevel() {
        return "off";
      },
    },
    async when_startingSession(ctx: unknown) {
      for (const handler of sessionStartHandlers) {
        await handler({}, ctx);
      }
    },
    when_emitting(event: string, payload: unknown) {
      for (const handler of eventHandlers.get(event) ?? []) {
        handler(payload);
      }
    },
  };
}

function given_footerContext() {
  let footerFactory: Function | undefined;

  return {
    ctx: {
      hasUI: true,
      model: { provider: "test", id: "model", reasoning: false },
      getContextUsage() {
        return null;
      },
      sessionManager: {
        getEntries() {
          return [];
        },
      },
      ui: {
        setFooter(factory: Function) {
          footerFactory = factory;
        },
      },
    },
    when_gettingFooterFactory() {
      assert.ok(footerFactory, "Expected footer to be registered");
      return footerFactory as Function;
    },
  };
}

function given_theme() {
  return {
    fg(color: string, text: string) {
      return `<${color}>${text}</${color}>`;
    },
  };
}

function given_tui() {
  let requestRenderCalls = 0;

  return {
    tui: {
      requestRender() {
        requestRenderCalls += 1;
      },
    },
    when_gettingRequestRenderCalls() {
      return requestRenderCalls;
    },
  };
}

function given_footerData(statuses: Map<string, string> = new Map()) {
  return {
    getGitBranch() {
      return "main";
    },
    getExtensionStatuses() {
      return statuses;
    },
  };
}

function given_renderedFooter(
  footerFactory: Function,
  footerData = given_footerData(),
) {
  const tui = given_tui();
  const component = footerFactory(tui.tui, given_theme(), footerData);

  return {
    when_renderingLines(width: number = 120) {
      return component.render(width);
    },
    when_gettingRequestRenderCalls: tui.when_gettingRequestRenderCalls,
  };
}

function when_renderingDirectoryLine(footerFactory: Function): string {
  return given_renderedFooter(footerFactory).when_renderingLines()[1];
}

test("footer GIVEN no runtime state events WHEN rendering after session start THEN it defaults to disabled sandbox, damage-control, and MCP icons", async () => {
  const { pi, when_startingSession } = given_mockPi();
  const { ctx, when_gettingFooterFactory } = given_footerContext();

  footerExtension(pi as never);
  await when_startingSession(ctx as never);

  const actual = when_renderingDirectoryLine(when_gettingFooterFactory());

  assert.ok(actual.includes(`<error>${ICONS["sandbox-disabled"]}</error>`));
  assert.ok(!actual.includes(ICONS["sandbox-enabled"]));
  assert.ok(
    actual.includes(`<error>${ICONS["damage-control-disabled"]}</error>`),
  );
  assert.ok(!actual.includes(ICONS["damage-control-enabled"]));
  assert.ok(actual.includes(`<error>${ICONS["mcp-disabled"]}</error>`));
  assert.ok(!actual.includes(ICONS["mcp-enabled"]));
});

test("footer GIVEN a sandbox enabled runtime event WHEN rendering THEN it shows the enabled sandbox icon", async () => {
  const { pi, when_startingSession, when_emitting } = given_mockPi();
  const { ctx, when_gettingFooterFactory } = given_footerContext();

  footerExtension(pi as never);
  await when_startingSession(ctx as never);
  when_emitting("sandbox:state-changed", true);

  const actual = when_renderingDirectoryLine(when_gettingFooterFactory());

  assert.ok(actual.includes(`<dim>${ICONS["sandbox-enabled"]}</dim>`));
  assert.ok(!actual.includes(ICONS["sandbox-disabled"]));
});

test("footer GIVEN a damage-control enabled runtime event before session start WHEN rendering THEN it shows the enabled damage-control icon", async () => {
  const { pi, when_startingSession, when_emitting } = given_mockPi();
  const { ctx, when_gettingFooterFactory } = given_footerContext();

  footerExtension(pi as never);
  when_emitting("damage-control:state-changed", true);
  await when_startingSession(ctx as never);

  const actual = when_renderingDirectoryLine(when_gettingFooterFactory());

  assert.ok(actual.includes(`<dim>${ICONS["damage-control-enabled"]}</dim>`));
  assert.ok(!actual.includes(ICONS["damage-control-disabled"]));
});

test("footer GIVEN an MCP adapter enabled runtime event WHEN rendering THEN it shows the enabled MCP icon and requests a rerender", async () => {
  const { pi, when_startingSession, when_emitting } = given_mockPi();
  const { ctx, when_gettingFooterFactory } = given_footerContext();

  footerExtension(pi as never);
  await when_startingSession(ctx as never);

  const renderedFooter = given_renderedFooter(when_gettingFooterFactory());
  when_emitting("mcp-adapter:state-changed", true);

  const actual = {
    directoryLine: renderedFooter.when_renderingLines()[1],
    requestRenderCalls: renderedFooter.when_gettingRequestRenderCalls(),
  };

  assert.ok(
    actual.directoryLine.includes(`<dim>${ICONS["mcp-enabled"]}</dim>`),
  );
  assert.ok(!actual.directoryLine.includes(ICONS["mcp-disabled"]));
  assert.equal(actual.requestRenderCalls, 1);
});

test("footer GIVEN MCP disabled and extension statuses WHEN rendering THEN it omits the mcp status entry but keeps the others", async () => {
  const { pi, when_startingSession } = given_mockPi();
  const { ctx, when_gettingFooterFactory } = given_footerContext();

  footerExtension(pi as never);
  await when_startingSession(ctx as never);

  const renderedFooter = given_renderedFooter(
    when_gettingFooterFactory(),
    given_footerData(
      new Map([
        ["mcp", "mcp ready"],
        ["sandbox", "sandbox on"],
      ]),
    ),
  );

  const actual = renderedFooter.when_renderingLines()[2] ?? "";

  assert.ok(actual.includes("sandbox on"));
  assert.ok(!actual.includes("mcp ready"));
});
