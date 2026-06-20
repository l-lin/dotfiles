import assert from "node:assert/strict";
import test from "node:test";

import workingMessageExtension from "./index.js";

const TOKEN_METRIC_CHANGED_EVENT = "token-metric:changed";

type ExtensionHandler = (event: unknown, ctx: unknown) => unknown;
type EventBusHandler = (data: unknown) => void;

function given_mockPi() {
  const extensionHandlers = new Map<string, ExtensionHandler[]>();
  const eventBusHandlers = new Map<string, EventBusHandler[]>();

  return {
    pi: {
      on(event: string, handler: ExtensionHandler) {
        const handlers = extensionHandlers.get(event) ?? [];
        handlers.push(handler);
        extensionHandlers.set(event, handlers);
      },
      events: {
        on(event: string, handler: EventBusHandler) {
          const handlers = eventBusHandlers.get(event) ?? [];
          handlers.push(handler);
          eventBusHandlers.set(event, handlers);
        },
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
    when_emittingBusEvent(event: string, payload: unknown) {
      for (const handler of eventBusHandlers.get(event) ?? []) {
        handler(payload);
      }
    },
  };
}

function given_workingMessageContext() {
  const workingMessages: Array<string | undefined> = [];

  return {
    ctx: {
      ui: {
        setWorkingMessage(message?: string) {
          workingMessages.push(message);
        },
      },
    },
    when_gettingLatestWorkingMessage() {
      return workingMessages.at(-1);
    },
  };
}

function given_intervalController() {
  let intervalCallback: (() => void) | undefined;
  const originalSetInterval = global.setInterval;
  const originalClearInterval = global.clearInterval;

  global.setInterval = ((callback: () => void) => {
    intervalCallback = callback;
    return 1 as unknown as NodeJS.Timeout;
  }) as typeof setInterval;

  global.clearInterval = (() => {
    intervalCallback = undefined;
  }) as typeof clearInterval;

  return {
    when_tickingInterval() {
      assert.ok(
        intervalCallback,
        "Expected interval callback to be registered",
      );
      intervalCallback();
    },
    restore() {
      global.setInterval = originalSetInterval;
      global.clearInterval = originalClearInterval;
    },
  };
}

test("working-message GIVEN a token metric event WHEN the timer ticks THEN it appends formatted tok/s", async () => {
  const { pi, when_emittingExtensionEvent, when_emittingBusEvent } =
    given_mockPi();
  const { ctx, when_gettingLatestWorkingMessage } =
    given_workingMessageContext();
  const interval = given_intervalController();

  try {
    workingMessageExtension(pi as never);

    await when_emittingExtensionEvent(
      "agent_start",
      { type: "agent_start" },
      ctx,
    );
    when_emittingBusEvent(TOKEN_METRIC_CHANGED_EVENT, { tps: 12.34 });
    interval.when_tickingInterval();

    const actual = when_gettingLatestWorkingMessage() ?? "";
    assert.match(actual, /@ 12\.3tok\/s/);
  } finally {
    interval.restore();
  }
});

test("working-message GIVEN no token metric event WHEN the timer ticks THEN it omits tok/s", async () => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_gettingLatestWorkingMessage } =
    given_workingMessageContext();
  const interval = given_intervalController();

  try {
    workingMessageExtension(pi as never);

    await when_emittingExtensionEvent(
      "agent_start",
      { type: "agent_start" },
      ctx,
    );
    interval.when_tickingInterval();

    const actual = when_gettingLatestWorkingMessage() ?? "";
    assert.doesNotMatch(actual, /tok\/s/);
  } finally {
    interval.restore();
  }
});
