import assert from "node:assert/strict";
import { afterEach, beforeEach, test } from "node:test";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ClassifierResult } from "@earendil-works/pi-ai";
import verdict, { debugMessage } from "./index.js";
import {
  classifyNative,
  composeVerdictLine,
  confidencePercent,
  resolveModelSpec,
  type NativeClassifierSpec,
} from "./classifier.js";
import {
  DEFAULT_CLASSIFIER,
  DEFAULT_SETTINGS,
  agentDirPath,
  loadUserRules,
  saveEnabled,
} from "./settings.js";
import {
  buildProtectedSet,
  IntegrityWatch,
  isProtectedWritePath,
  selfProtectCheck,
} from "./protection.js";

let home: string;
let previousEnvironment: NodeJS.ProcessEnv;
beforeEach(() => {
  previousEnvironment = { ...process.env };
  home = fs.mkdtempSync(path.join(os.tmpdir(), "verdict-local-test-"));
  process.env.HOME = home;
  delete process.env.PI_AUTO_MODE_MODEL;
  delete process.env.PI_AUTO_MODE_DEBUG;
});
afterEach(() => {
  for (const key of Object.keys(process.env)) {
    if (!(key in previousEnvironment)) delete process.env[key];
  }
  Object.assign(process.env, previousEnvironment);
  fs.rmSync(home, { recursive: true, force: true });
});

function given_settings(
  verdictSettings: object,
  siblings: object = {},
): string {
  assert.equal(agentDirPath(), path.join(home, ".pi", "agent"));
  const file = path.join(agentDirPath(), "settings.json");
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(
    file,
    JSON.stringify({
      defaultProvider: "example",
      extensionSettings: {
        other: { enabled: true },
        verdict: verdictSettings,
        ...siblings,
      },
    }),
  );
  return file;
}
function given_model(
  id = "microsoft-decision-1",
  provider = "github-copilot",
): NativeClassifierSpec {
  return {
    type: "classifier",
    id,
    provider,
    name: id,
    api: "typesafe-system-one",
    baseUrl: "https://synthetic.invalid",
    input: ["text"],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 32768,
  };
}
function given_answer(choice = "allow", confidence = 0.91): ClassifierResult {
  return {
    api: "typesafe-system-one",
    provider: "github-copilot",
    model: "microsoft-decision-1",
    stopReason: "stop",
    timestamp: 0,
    answers: {
      verdict: {
        type: "choice",
        choice,
        confidence,
        probabilities: { allow: 0.91, ask: 0.06, deny: 0.03 },
      },
    },
  };
}
function given_harness() {
  const handlers: Record<string, (event: any, ctx: any) => any> = {};
  const commands: Record<
    string,
    { handler: (args: string, ctx: any) => Promise<void> }
  > = {};
  const subscribers = new Map<string, Array<(value: unknown) => void>>();
  const events: Array<{ name: string; data: any }> = [];
  const notifications: string[] = [];
  const nativeCalls: Array<{
    model: NativeClassifierSpec;
    context: any;
    options: any;
  }> = [];
  const chatCalls: any[] = [];
  const nativeModels = new Map<string, NativeClassifierSpec>();
  const providers: Array<{ name: string; config: any }> = [];
  const bus = {
    on(name: string, handler: (value: unknown) => void) {
      subscribers.set(name, [...(subscribers.get(name) ?? []), handler]);
    },
    emit(name: string, data: unknown) {
      events.push({ name, data });
      for (const handler of subscribers.get(name) ?? []) handler(data);
    },
  };
  const ctx: any = {
    cwd: home,
    hasUI: true,
    model: { id: "session", provider: "example" },
    sessionManager: { getBranch: () => [], getSessionId: () => "synthetic" },
    modelRegistry: {
      findOfType: (_type: string, provider: string, id: string) =>
        nativeModels.get(`${provider}/${id}`),
      find: (provider: string, id: string) =>
        provider === "example" ? { id, provider } : undefined,
      getProviderAuthStatus: () => ({ configured: true }),
      hasConfiguredAuth: () => true,
      classify: async (
        model: NativeClassifierSpec,
        context: unknown,
        options: unknown,
      ) => {
        nativeCalls.push({ model, context, options });
        return given_answer();
      },
      complete: async (model: unknown, context: unknown, options: unknown) => {
        chatCalls.push({ model, context, options });
        return {
          stopReason: "stop",
          content: [
            { type: "text", text: "<verdict>allow</verdict> Synthetic test" },
          ],
        };
      },
    },
    ui: {
      notify: (message: string) => notifications.push(message),
      confirm: async () => true,
      select: async (_title: string, choices: string[]) => choices[0],
    },
  };
  const pi: any = {
    events: bus,
    registerProvider(name: string, config: any) {
      providers.push({ name, config });
      for (const model of config.models) {
        nativeModels.set(`${name}/${model.id}`, {
          ...model,
          provider: name,
          baseUrl: config.baseUrl,
        });
      }
    },
    registerFlag: () => assert.fail("Verdict must not register flags"),
    getFlag: () => assert.fail("Verdict must not read flags"),
    on: (name: string, handler: any) => {
      handlers[name] = handler;
    },
    registerCommand: (name: string, command: any) => {
      commands[name] = command;
    },
    registerShortcut: () => assert.fail("Verdict must not register shortcuts"),
  };
  verdict(pi);
  handlers.session_start({}, ctx);
  return {
    ctx,
    handlers,
    commands,
    events,
    bus,
    notifications,
    nativeCalls,
    chatCalls,
    nativeModels,
    providers,
  };
}
function when_tool_call(
  harness: ReturnType<typeof given_harness>,
  toolName = "bash",
  input: object = { command: "echo synthetic" },
) {
  return harness.handlers.tool_call({ toolName, input }, harness.ctx);
}

test("GIVEN no verdict settings WHEN rules load THEN safe defaults apply without a configuration write", () => {
  const actual = loadUserRules();
  const expected = DEFAULT_SETTINGS;
  assert.equal(actual.enabled, expected.enabled);
  assert.deepEqual(actual.rules.denyPaths, expected.denyPaths);
  assert.deepEqual(actual.rules.ignoreTools, expected.ignoreTools);
  assert.equal(actual.rules.audit, true);
  assert.equal(actual.rules.debug, true);
  assert.equal(actual.rules.classifierMinConfidence, null);
  assert.equal(fs.existsSync(agentDirPath()), false);
});

test("GIVEN default debug settings WHEN a classifier allows THEN the tool appears above icon scores", async () => {
  const harness = given_harness();
  const answer = given_answer("allow", 0.46);
  const scores = answer.answers.verdict;
  assert.equal(scores.type, "choice");
  if (scores.type === "choice") {
    scores.probabilities = { allow: 0.64, ask: 0.23, deny: 0.12 };
  }
  harness.ctx.modelRegistry.classify = async () => answer;
  await when_tool_call(harness, "bash", {
    command: "curl -I https://example.org",
  });
  const actual = harness.notifications;
  const expected = [
    " bash: curl -I https://example.org\n  64% ( 46% 󰋗 23% 󰅙 12%)",
  ];
  assert.deepEqual(actual, expected);
});

test("GIVEN a rule decision without a reason WHEN a file tool runs THEN no debug notification appears", async () => {
  const harness = given_harness();
  for (const toolName of ["read", "write", "edit"]) {
    const actual = await when_tool_call(harness, toolName, { path: "package.json" });
    const expected = undefined;
    assert.equal(actual, expected);
  }
  assert.deepEqual(harness.notifications, []);
  assert.equal(harness.nativeCalls.length, 0);
});

test("GIVEN debug disabled in settings WHEN a classifier allows THEN no debug notification appears", async () => {
  given_settings({ debug: false });
  process.env.PI_AUTO_MODE_DEBUG = "1";
  const harness = given_harness();
  await when_tool_call(harness);
  const actual = harness.notifications;
  const expected: string[] = [];
  assert.deepEqual(actual, expected);
});

test("GIVEN invalid debug settings WHEN rules load THEN debug stays enabled and reports the value", () => {
  given_settings({ debug: "false" });
  const actual = loadUserRules();
  const expected = true;
  assert.equal(actual.rules.debug, expected);
  assert.deepEqual(actual.skipped, ['debug: "false"; expected a boolean']);
});

test("GIVEN ask and deny scores WHEN debug formats them THEN each decision uses its icon", () => {
  for (const verdict of ["ask", "deny"] as const) {
    const actual = debugMessage(
      {
        verdict,
        reason: `classifier: ${verdict} 64% (confidence 46%; allow 23%, ${verdict === "ask" ? "deny" : "ask"} 12%)`,
        source: "classifier",
        degraded: false,
      },
      "bash: echo synthetic",
    );
    const expected =
      verdict === "ask"
        ? " bash: echo synthetic\n 󰋗 64% ( 46%  23% 󰅙 12%)"
        : " bash: echo synthetic\n 󰅙 64% ( 46%  23% 󰋗 12%)";
    assert.equal(actual, expected);
  }
});

test("GIVEN debug enabled WHEN the classifier asks or denies THEN one notification preserves the permission decision", async () => {
  for (const verdict of ["ask", "deny"] as const) {
    const harness = given_harness();
    harness.ctx.modelRegistry.classify = async () => given_answer(verdict);
    let confirmed = false;
    harness.ctx.ui.confirm = async () => {
      confirmed = true;
      return true;
    };
    const actual = await when_tool_call(harness);
    const expected = verdict === "deny" ? true : undefined;
    assert.equal(actual?.block, expected);
    assert.equal(confirmed, verdict === "ask");
    assert.equal(harness.notifications.length, 1);
    assert.match(harness.notifications[0], /^ bash: echo synthetic\n [󰋗󰅙]/u);
  }
});

test("GIVEN a protected path WHEN debug formats the decision THEN the path stays hidden", () => {
  const actual = debugMessage(
    {
      verdict: "ask",
      reason: "Protected path access requires approval",
      source: "protected-path",
      detail: "/secret/project",
      degraded: false,
    },
    "read: /secret/project/file.txt",
  );
  const expected =
    " read: [protected path]\n 󰋗 (protected-path): Protected path access requires approval";
  assert.equal(actual, expected);
});

test("GIVEN removed command rules WHEN a matching command runs THEN the classifier controls the decision", async () => {
  given_settings({ allow: ["echo"], deny: ["echo"] });
  for (const choice of ["allow", "deny"] as const) {
    const harness = given_harness();
    harness.ctx.modelRegistry.classify = async () => {
      harness.nativeCalls.push({ model: given_model(), context: {}, options: {} });
      return given_answer(choice);
    };
    const actual = await when_tool_call(harness);
    const expected = choice === "deny" ? true : undefined;
    assert.equal(actual?.block, expected);
    assert.equal(harness.nativeCalls.length, 1);
  }
});

test("GIVEN headless artifact output WHEN the classifier asks THEN no special write exemption applies", async () => {
  const harness = given_harness();
  harness.ctx.cwd = path.join(home, "project");
  harness.ctx.hasUI = false;
  harness.ctx.modelRegistry.classify = async () => {
    harness.nativeCalls.push({
      model: given_model(),
      context: {},
      options: {},
    });
    return given_answer("ask");
  };
  const actual = await when_tool_call(harness, "write", {
    path: path.join(
      agentDirPath(),
      "sessions",
      "synthetic",
      "subagent-artifacts",
      "output.md",
    ),
    content: "Synthetic output",
  });
  const expected = true;
  assert.equal(actual?.block, expected);
  assert.equal(harness.nativeCalls.length, 1);
});

test("GIVEN shared settings WHEN verdict toggles THEN sibling settings survive and runtime status changes", async () => {
  const file = given_settings({ enabled: true });
  const harness = given_harness();
  await harness.commands["cmd:verdict-toggle"].handler("", harness.ctx);
  const actual = JSON.parse(fs.readFileSync(file, "utf8"));
  const expected = {
    defaultProvider: "example",
    extensionSettings: {
      other: { enabled: true },
      verdict: { enabled: false },
    },
  };
  assert.deepEqual(actual, expected);
  assert.deepEqual(harness.events.at(-1), {
    name: "verdict:changed",
    data: { enabled: false },
  });
  assert.equal(await when_tool_call(harness), undefined);
  assert.equal(harness.nativeCalls.length, 0);
  await harness.commands["cmd:verdict-toggle"].handler("", harness.ctx);
  assert.equal(await when_tool_call(harness), undefined);
  assert.equal(harness.nativeCalls.length, 1);
});

test("GIVEN saved disablement WHEN the session starts THEN verdict stays disabled without a settings write", async () => {
  const file = given_settings({ enabled: false });
  const harness = given_harness();
  const actual = await when_tool_call(harness);
  const expected = undefined;
  assert.equal(actual, expected);
  assert.equal(harness.nativeCalls.length, 0);
  assert.equal(
    JSON.parse(fs.readFileSync(file, "utf8")).extensionSettings.verdict.enabled,
    false,
  );
  assert.deepEqual(harness.events[0].data, { enabled: false });
});

test("GIVEN no classifier override WHEN a gray action runs THEN verdict uses native local Kev", async () => {
  const harness = given_harness();
  const actual = await when_tool_call(harness);
  const expected = undefined;
  assert.equal(actual, expected);
  assert.equal(harness.chatCalls.length, 0);
  assert.equal(harness.nativeCalls.length, 1);
  assert.equal(harness.nativeCalls[0].model.id, "kev");
  assert.equal(harness.nativeCalls[0].model.provider, "verdict-local");
  assert.equal(
    harness.nativeCalls[0].model.baseUrl,
    "http://127.0.0.1:11436/v1",
  );
  assert.equal(harness.providers[0].config.apiKey, "local");
  assert.equal(
    typeof harness.providers[0].config.classifiers["typesafe-system-one"]
      .classify,
    "function",
  );
  assert.equal(harness.nativeCalls[0].options.timeoutMs, 25000);
  assert.match(
    harness.nativeCalls[0].context.state.transcript,
    /bash: echo synthetic$/,
  );
});

test("GIVEN model overrides WHEN a gray action runs THEN environment precedes shared settings", async () => {
  given_settings({ classifierModel: "example/configured" });
  process.env.PI_AUTO_MODE_MODEL = "example/environment:low";
  const harness = given_harness();
  await when_tool_call(harness);
  const actual = harness.chatCalls[0];
  const expected = "environment";
  assert.equal(actual.model.id, expected);
  assert.equal(actual.options.effort, "low");
  delete process.env.PI_AUTO_MODE_MODEL;
  const configured = given_harness();
  await when_tool_call(configured);
  assert.equal(configured.chatCalls[0].model.id, "configured");
});

test("GIVEN an unavailable local classifier WHEN gray actions run THEN verdict warns once and uses the session model", async () => {
  const harness = given_harness();
  harness.nativeModels.clear();
  await when_tool_call(harness);
  await when_tool_call(harness);
  const actual = harness.notifications.filter((message) =>
    message.includes("unavailable"),
  );
  const expected = 1;
  assert.equal(actual.length, expected);
  assert.equal(harness.chatCalls.length, 2);
  assert.equal(harness.chatCalls[0].model.id, "session");
});

test("GIVEN no classifier authentication WHEN resolution runs THEN no native layer resolves", () => {
  const harness = given_harness();
  harness.ctx.modelRegistry.getProviderAuthStatus = () => ({
    configured: false,
  });
  const actual = resolveModelSpec(harness.ctx, DEFAULT_CLASSIFIER, () => {});
  const expected = null;
  assert.equal(actual, expected);
});

test("GIVEN a Copilot classifier response WHEN verdict formats it THEN the label does not name Jev", async () => {
  const actual = await classifyNative(
    async () => given_answer(),
    given_model(),
    { getBranch: () => [], getSessionId: () => "synthetic" },
    "bash: echo synthetic",
    undefined,
    1000,
  );
  const expected = "allow";
  assert.equal(actual.verdict, expected);
  assert.match(actual.reason, /^classifier:/);
  assert.equal(actual.confidence, 91);
  assert.equal(actual.auditRaw?.thinking, null);
  assert.equal(confidencePercent(0.496), 49);
});

test("GIVEN failed or malformed native responses WHEN classification runs THEN verdict fails closed", async () => {
  const host = { getBranch: () => [], getSessionId: () => "synthetic" };
  const responses = [
    {
      ...given_answer(),
      stopReason: "error",
      errorMessage: "Synthetic failure",
    },
    { ...given_answer(), answers: {} },
    {
      ...given_answer(),
      answers: { verdict: { type: "score", score: 2, confidence: 0.9 } },
    },
    given_answer("unknown"),
    given_answer("allow", Number.NaN),
    {
      ...given_answer(),
      answers: {
        verdict: { type: "choice", choice: "allow", probabilities: {} },
      },
    },
  ];
  for (const response of responses) {
    const actual = await classifyNative(
      async () => response as ClassifierResult,
      given_model(),
      host,
      "synthetic",
      undefined,
      1000,
    );
    const expected = "fail-closed";
    assert.equal(actual.source, expected);
    assert.equal(actual.verdict, "deny");
  }
  const actual = await classifyNative(
    async () => {
      throw new Error("Synthetic transport error");
    },
    given_model(),
    host,
    "synthetic",
    undefined,
    1000,
  );
  assert.equal(actual.source, "fail-closed");
  const aborted = new AbortController();
  aborted.abort();
  let calls = 0;
  await classifyNative(
    async () => {
      calls++;
      return given_answer();
    },
    given_model(),
    host,
    "synthetic",
    aborted.signal,
    1000,
  );
  assert.equal(calls, 0);
  assert.throws(() =>
    composeVerdictLine(
      { choice: "invalid", confidence: 0.9, probabilities: {} },
      "typesafe-system-one",
    ),
  );
});

test("GIVEN sibling settings changes WHEN direct file tools run THEN verdict permits only section-preserving changes", () => {
  const file = given_settings({ enabled: true });
  const prot = buildProtectedSet(agentDirPath(), null);
  const content = fs.readFileSync(file, "utf8");
  const actual = selfProtectCheck(
    "write",
    {
      path: file,
      content: content.replace(
        '"other":{"enabled":true}',
        '"other":{"enabled":false}',
      ),
    },
    home,
    prot,
  );
  const expected = null;
  assert.equal(actual, expected);
  assert.equal(
    selfProtectCheck(
      "edit",
      {
        path: file,
        edits: [
          {
            oldText: '"other":{"enabled":true}',
            newText: '"other":{"enabled":false}',
          },
        ],
      },
      home,
      prot,
    ),
    null,
  );
  for (const input of [
    { path: file, content: "{}" },
    { path: file, content: "invalid" },
    {
      path: file,
      edits: [
        {
          oldText: '"verdict":{"enabled":true}',
          newText: '"verdict":{"enabled":false}',
        },
      ],
    },
  ]) {
    assert.equal(
      selfProtectCheck("content" in input ? "write" : "edit", input, home, prot)
        ?.verdict,
      "deny",
    );
  }
  const alias = path.join(home, "settings-alias.json");
  fs.symlinkSync(file, alias);
  assert.equal(
    selfProtectCheck("write", { path: alias, content: "{}" }, home, prot)
      ?.verdict,
    "deny",
  );
});

test("GIVEN shared settings WHEN only siblings or key order change THEN integrity remains unchanged", () => {
  const file = given_settings({ enabled: true, audit: false });
  const watch = new IntegrityWatch(
    buildProtectedSet(agentDirPath(), null).watchBases,
  );
  given_settings(
    { audit: false, enabled: true },
    { other: { enabled: false } },
  );
  const actual = watch.detect();
  const expected: unknown[] = [];
  assert.deepEqual(actual, expected);
  assert.equal(
    JSON.parse(fs.readFileSync(file, "utf8")).extensionSettings.other.enabled,
    false,
  );
});

test("GIVEN tampered verdict settings WHEN restoration runs THEN only verdict settings return to the baseline", () => {
  const file = given_settings({ enabled: true });
  const watch = new IntegrityWatch(
    buildProtectedSet(agentDirPath(), null).watchBases,
  );
  given_settings(
    { enabled: false },
    { other: { enabled: false }, extra: { value: 2 } },
  );
  watch.restoreAndFailClose(watch.detect(), "Synthetic tamper");
  const actual = JSON.parse(fs.readFileSync(file, "utf8"));
  const expected = {
    other: { enabled: false },
    extra: { value: 2 },
    verdict: { enabled: true },
  };
  assert.deepEqual(actual.extensionSettings, expected);
  assert.equal(watch.tampered, true);
});

test("GIVEN headless settings tampering WHEN a tool runs THEN verdict restores settings and remains blocked", async () => {
  const file = given_settings({ enabled: true });
  const harness = given_harness();
  harness.ctx.hasUI = false;
  given_settings({ enabled: false });
  const actual = await when_tool_call(harness);
  const expected = true;
  assert.equal(actual?.block, expected);
  assert.equal(
    JSON.parse(fs.readFileSync(file, "utf8")).extensionSettings.verdict.enabled,
    true,
  );
  assert.equal((await when_tool_call(harness))?.block, true);
  assert.equal(harness.nativeCalls.length, 0);
});

test("GIVEN user-approved settings changes WHEN a tool runs THEN new rules wait until the next session", async () => {
  given_settings({ enabled: true, builtinDenyFloor: false });
  const harness = given_harness();
  given_settings({ enabled: true, builtinDenyFloor: true });
  const input = { command: "sudo echo synthetic" };
  const actual = await when_tool_call(harness, "bash", input);
  const expected = undefined;
  assert.equal(actual, expected);
  assert.equal(harness.nativeCalls.length, 1);
  harness.handlers.session_start({}, harness.ctx);
  assert.equal((await when_tool_call(harness, "bash", input))?.block, true);
  assert.equal(harness.nativeCalls.length, 1);
});

test("GIVEN installed module tampering WHEN enablement saves THEN only the settings baseline changes", () => {
  given_settings({ enabled: true });
  const directory = path.join(agentDirPath(), "extensions", "verdict");
  fs.mkdirSync(directory, { recursive: true });
  const file = path.join(directory, "index.ts");
  const helper = path.join(
    agentDirPath(),
    "extensions",
    "tool-settings",
    "index.ts",
  );
  fs.mkdirSync(path.dirname(helper), { recursive: true });
  fs.writeFileSync(file, "original");
  fs.writeFileSync(helper, "shared helper");
  const prot = buildProtectedSet(agentDirPath(), file);
  const watch = new IntegrityWatch(prot.watchBases);
  fs.writeFileSync(file, "tampered");
  saveEnabled(false);
  watch.refreshSettingsBaseline();
  const actual = watch.detect();
  const expected = [...new Set([file, fs.realpathSync(file)])].map((file) => ({
    file,
    kind: "extension",
  }));
  assert.deepEqual(actual, expected);
  watch.restoreAndFailClose(actual, "Synthetic tamper");
  assert.equal(fs.readFileSync(file, "utf8"), "original");
  assert.equal(
    isProtectedWritePath(path.join(directory, "new.ts"), home, prot),
    true,
  );
  assert.equal(isProtectedWritePath(helper, home, prot), true);
  assert.equal(
    isProtectedWritePath(
      path.join(agentDirPath(), "extensions", "footer", "index.ts"),
      home,
      prot,
    ),
    false,
  );
});

test("GIVEN malformed shared settings WHEN enablement saves THEN verdict does not overwrite the file", () => {
  const file = given_settings({ enabled: true });
  fs.writeFileSync(file, "malformed");
  const actual = () => saveEnabled(false);
  const expected = /JSON/;
  assert.throws(actual, expected);
  assert.equal(fs.readFileSync(file, "utf8"), "malformed");
  assert.equal(loadUserRules().enabled, true);
});

test("GIVEN a runtime status request WHEN verdict is active THEN it reports saved settings and command details", async () => {
  given_settings({ enabled: false, debug: false });
  const harness = given_harness();
  harness.bus.emit("verdict:request-status", {});
  const actual = harness.events.at(-1);
  const expected = { name: "verdict:changed", data: { enabled: false } };
  assert.deepEqual(actual, expected);
  assert.deepEqual(Object.keys(harness.commands).sort(), [
    "cmd:verdict-status",
    "cmd:verdict-toggle",
  ]);
  await harness.commands["cmd:verdict-status"].handler("", harness.ctx);
  assert.match(harness.notifications.at(-1)!, /classifier: verdict-local\/kev/);
  assert.match(harness.notifications.at(-1)!, /debug: disabled/);
  harness.handlers.session_shutdown({}, harness.ctx);
  assert.deepEqual(harness.events.at(-1)?.data, { enabled: undefined });
});
