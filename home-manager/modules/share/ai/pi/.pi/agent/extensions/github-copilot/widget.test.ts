import assert from "node:assert/strict";
import test from "node:test";
import { updateWidget } from "./widget.js";
import type { AuthStatus, UsageData } from "./types.js";

function given_widgetContext() {
  let widgetLines: string[] | undefined;

  return {
    ctx: {
      ui: {
        theme: {
          fg(_color: string, text: string) {
            return text;
          },
        },
        setWidget(_id: string, lines: string[]) {
          widgetLines = lines;
        },
      },
    },
    when_gettingWidgetLine() {
      assert.ok(widgetLines, "Expected widget to be rendered");
      return widgetLines[0];
    },
  };
}

function given_limitedUsageData(resetDate: string): UsageData {
  return {
    used: 1,
    quota: 4,
    remaining: 3,
    resetDate,
    unlimited: false,
    overagePermitted: false,
    plan: "copilot-pro",
  };
}

function given_authenticatedStatus(): AuthStatus {
  return { hasToken: true };
}

test("updateWidget GIVEN the first day of the month WHEN rendering usage THEN it shows 0% month progress instead of the reset date", (t) => {
  t.mock.method(Date, "now", () => new Date(2026, 4, 1, 12, 0, 0).valueOf());
  const { ctx, when_gettingWidgetLine } = given_widgetContext();

  updateWidget(
    ctx as never,
    given_limitedUsageData("2026-06-01"),
    given_authenticatedStatus(),
  );

  const actual = when_gettingWidgetLine();

  assert.ok(actual.includes("(0%)"));
  assert.ok(!actual.includes("2026-06-01"));
});

test("updateWidget GIVEN the last day of the month WHEN rendering usage THEN it shows 100% month progress instead of the reset date", (t) => {
  t.mock.method(Date, "now", () => new Date(2026, 4, 31, 12, 0, 0).valueOf());
  const { ctx, when_gettingWidgetLine } = given_widgetContext();

  updateWidget(
    ctx as never,
    given_limitedUsageData("2026-06-01"),
    given_authenticatedStatus(),
  );

  const actual = when_gettingWidgetLine();

  assert.ok(actual.includes("(100%)"));
  assert.ok(!actual.includes("2026-06-01"));
});
