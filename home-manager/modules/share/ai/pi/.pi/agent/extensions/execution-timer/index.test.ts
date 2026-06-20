import assert from "node:assert/strict";
import test from "node:test";

import executionTimerExtension from "./index.js";

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

function given_notificationContext() {
  const notifications: string[] = [];

  return {
    ctx: {
      hasUI: true,
      ui: {
        notify(message: string) {
          notifications.push(message);
        },
      },
    },
    when_gettingLatestNotification() {
      return notifications.at(-1);
    },
  };
}

function given_clock(initialMs: number) {
  let currentMs = initialMs;
  const originalNow = Date.now;

  Date.now = () => currentMs;

  return {
    advanceMs(ms: number) {
      currentMs += ms;
    },
    restore() {
      Date.now = originalNow;
    },
  };
}

test("execution-timer GIVEN a token metric event WHEN the agent ends THEN it includes tok/s in the notification", async () => {
  const { pi, when_emittingExtensionEvent, when_emittingBusEvent } =
    given_mockPi();
  const { ctx, when_gettingLatestNotification } = given_notificationContext();
  const clock = given_clock(1_000);

  try {
    executionTimerExtension(pi as never);

    await when_emittingExtensionEvent(
      "agent_start",
      { type: "agent_start" },
      ctx,
    );
    when_emittingBusEvent(TOKEN_METRIC_CHANGED_EVENT, { tps: 42.4 });
    clock.advanceMs(2_500);
    await when_emittingExtensionEvent("agent_end", { type: "agent_end" }, ctx);

    const actual = when_gettingLatestNotification() ?? "";
    assert.match(actual, /42\.4tok\/s/);
  } finally {
    clock.restore();
  }
});

test("execution-timer GIVEN no token metric event WHEN the agent ends THEN it omits tok/s from the notification", async () => {
  const { pi, when_emittingExtensionEvent } = given_mockPi();
  const { ctx, when_gettingLatestNotification } = given_notificationContext();
  const clock = given_clock(1_000);

  try {
    executionTimerExtension(pi as never);

    await when_emittingExtensionEvent(
      "agent_start",
      { type: "agent_start" },
      ctx,
    );
    clock.advanceMs(2_500);
    await when_emittingExtensionEvent("agent_end", { type: "agent_end" }, ctx);

    const actual = when_gettingLatestNotification() ?? "";
    assert.doesNotMatch(actual, /tok\/s/);
  } finally {
    clock.restore();
  }
});
