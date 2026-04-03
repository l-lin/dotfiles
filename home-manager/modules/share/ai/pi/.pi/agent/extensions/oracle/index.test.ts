import assert from "node:assert/strict";
import test from "node:test";
import oracleExtension from "./index.js";
import { getOracleRequestOptions } from "./execute.js";

type CommandHandler = (args: string, ctx: unknown) => Promise<void>;

function given_mockPi() {
  const commands = new Map<string, { handler: CommandHandler }>();

  return {
    pi: {
      registerCommand(name: string, options: { handler: CommandHandler }) {
        commands.set(name, options);
      },
      registerMessageRenderer() {},
    },
    when_gettingOracleCommand() {
      const command = commands.get("cmd:oracle");
      assert.ok(command, "Expected /cmd:oracle to be registered");
      return command.handler;
    },
  };
}

function given_oracleContext(options: {
  currentModel?: { id: string };
  resolvedAuth:
    | { ok: true; apiKey?: string; headers?: Record<string, string> }
    | { ok: false; error: string };
}) {
  const notifications: Array<{ message: string; type?: string }> = [];

  return {
    ctx: {
      hasUI: true,
      model: options.currentModel,
      modelRegistry: {
        find(provider: string, modelId: string) {
          if (provider === "openai" && modelId === "gpt-4.1-mini") {
            return {
              provider,
              id: modelId,
              api: "openai-responses",
              name: "GPT-4.1 Mini",
              baseUrl: "https://api.openai.com/v1",
              reasoning: false,
              input: ["text"],
              cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
              contextWindow: 1,
              maxTokens: 1,
            };
          }
          return undefined;
        },
        hasConfiguredAuth() {
          return true;
        },
        async getApiKeyAndHeaders() {
          return options.resolvedAuth;
        },
      },
      ui: {
        notify(message: string, type?: string) {
          notifications.push({ message, type });
        },
      },
    },
    notifications,
  };
}

test("oracle GIVEN models without resolved auth WHEN running command THEN it reports that no alternative models are available", async () => {
  const { pi, when_gettingOracleCommand } = given_mockPi();
  const { ctx, notifications } = given_oracleContext({
    resolvedAuth: { ok: false, error: "missing auth" },
  });

  oracleExtension(pi as never);

  await when_gettingOracleCommand()("Need a second opinion", ctx);

  assert.deepEqual(notifications, [
    {
      message: "No alternative models available. Check API keys.",
      type: "error",
    },
  ]);
});

test("oracle GIVEN a headers-only authenticated model WHEN resolving the -m flag THEN it treats that model as available", async () => {
  const { pi, when_gettingOracleCommand } = given_mockPi();
  const { ctx, notifications } = given_oracleContext({
    resolvedAuth: {
      ok: true,
      headers: { Authorization: "Bearer token" },
    },
  });

  oracleExtension(pi as never);

  await when_gettingOracleCommand()(
    "-m missing-model Need a second opinion",
    ctx,
  );

  assert.deepEqual(notifications, [
    {
      message: 'Model "missing-model" not available',
      type: "error",
    },
  ]);
});

test("getOracleRequestOptions GIVEN a headers-only model WHEN building request options THEN it preserves custom headers", () => {
  const signal = new AbortController().signal;

  const actual = getOracleRequestOptions(
    {
      provider: "github-copilot",
      modelId: "gpt-4.1",
      name: "GPT-4.1",
      model: {
        provider: "github-copilot",
        id: "gpt-4.1",
        api: "openai-responses",
        name: "GPT-4.1",
        baseUrl: "https://api.githubcopilot.com",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 1,
        maxTokens: 1,
      },
      headers: { Authorization: "Bearer token" },
    },
    signal,
  );

  assert.deepEqual(actual, {
    signal,
    apiKey: undefined,
    headers: { Authorization: "Bearer token" },
  });
});
