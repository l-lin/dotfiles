import assert from "node:assert/strict";
import test from "node:test";

import tokenMetricExtension from "./index.js";

const TOKEN_METRIC_CHANGED_EVENT = "token-metric:changed";

type ExtensionHandler = (event: unknown, ctx: unknown) => unknown;

type EmittedEvent = {
  channel: string;
  payload: unknown;
};

function given_mockPi() {
  const extensionHandlers = new Map<string, ExtensionHandler[]>();
  const emittedEvents: EmittedEvent[] = [];

  return {
    pi: {
      on(event: string, handler: ExtensionHandler) {
        const handlers = extensionHandlers.get(event) ?? [];
        handlers.push(handler);
        extensionHandlers.set(event, handlers);
      },
      events: {
        emit(channel: string, payload: unknown) {
          emittedEvents.push({ channel, payload });
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
    when_gettingLatestBusPayload(channel: string) {
      const matchingEvent = [...emittedEvents]
        .reverse()
        .find((event) => event.channel === channel);
      return matchingEvent?.payload;
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

function given_intervalController() {
  const originalSetInterval = global.setInterval;
  const originalClearInterval = global.clearInterval;

  global.setInterval = (() =>
    1 as unknown as NodeJS.Timeout) as typeof setInterval;
  global.clearInterval = (() => {}) as typeof clearInterval;

  return {
    restore() {
      global.setInterval = originalSetInterval;
      global.clearInterval = originalClearInterval;
    },
  };
}

test("token-metric GIVEN provider output usage WHEN the assistant stream updates THEN it emits provider-based tok/s", async () => {
  const { pi, when_emittingExtensionEvent, when_gettingLatestBusPayload } =
    given_mockPi();
  const clock = given_clock(1_000);
  const interval = given_intervalController();

  try {
    tokenMetricExtension(pi as never);

    await when_emittingExtensionEvent(
      "session_start",
      { type: "session_start", reason: "startup" },
      {},
    );
    await when_emittingExtensionEvent(
      "message_start",
      { type: "message_start", message: { role: "assistant" } },
      {},
    );
    clock.advanceMs(100);
    await when_emittingExtensionEvent(
      "message_update",
      {
        type: "message_update",
        message: { role: "assistant" },
        assistantMessageEvent: {
          type: "text_delta",
          delta: "hello",
          partial: {
            usage: { output: 50 },
          },
        },
      },
      {},
    );

    const actual = when_gettingLatestBusPayload(TOKEN_METRIC_CHANGED_EVENT);
    const expected = { tps: 10 };
    assert.deepEqual(actual, expected);
  } finally {
    interval.restore();
    clock.restore();
  }
});
