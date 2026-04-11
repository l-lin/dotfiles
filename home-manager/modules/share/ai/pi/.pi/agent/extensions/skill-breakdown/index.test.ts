import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import skillBreakdownExtension from "./index.js";
import { computeSkillBreakdown } from "./aggregation.js";
import { SkillBreakdownComponent } from "./component.js";
import { parseSkillSessionFile } from "./session-parser.js";

function given_tempDirectory(t: test.TestContext): string {
  const tempDirectory = fs.mkdtempSync(
    path.join(os.tmpdir(), "skill-breakdown-"),
  );

  t.after(() => {
    fs.rmSync(tempDirectory, { recursive: true, force: true });
  });

  return tempDirectory;
}

function given_tempHome(t: test.TestContext): string {
  const previousHome = process.env.HOME;
  const previousXdgConfigHome = process.env.XDG_CONFIG_HOME;
  const tempHome = given_tempDirectory(t);

  process.env.HOME = tempHome;
  delete process.env.XDG_CONFIG_HOME;

  t.after(() => {
    if (previousHome === undefined) delete process.env.HOME;
    else process.env.HOME = previousHome;

    if (previousXdgConfigHome === undefined) delete process.env.XDG_CONFIG_HOME;
    else process.env.XDG_CONFIG_HOME = previousXdgConfigHome;
  });

  return tempHome;
}

function given_sessionFile(options: {
  root: string;
  relativeDir?: string;
  fileName: string;
  entries: unknown[];
  modifiedAt?: Date;
}): string {
  const relativeDir = options.relativeDir ?? "project";
  const filePath = path.join(options.root, relativeDir, options.fileName);
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(
    filePath,
    options.entries.map((entry) => JSON.stringify(entry)).join("\n") + "\n",
  );

  if (options.modifiedAt) {
    fs.utimesSync(filePath, options.modifiedAt, options.modifiedAt);
  }

  return filePath;
}

function given_sessionStartEntry(timestamp: string, cwd: string): unknown {
  return {
    type: "session",
    timestamp,
    cwd,
  };
}

function given_readAssistantMessage(
  timestamp: string,
  reads: Array<{ id: string; skillName: string; model?: string }>,
): unknown {
  const firstModel = reads[0]?.model;

  return {
    type: "message",
    timestamp,
    provider: firstModel ? "test" : undefined,
    model: firstModel,
    message: {
      role: "assistant",
      content: reads.map((read) => ({
        type: "toolCall",
        id: read.id,
        name: "read",
        arguments: {
          path: `/Users/test/.config/ai/skills/${read.skillName}/SKILL.md`,
        },
      })),
    },
  };
}

function given_readToolResultMessage(options: {
  timestamp: string;
  toolCallId: string;
  isError?: boolean;
}): unknown {
  return {
    type: "message",
    timestamp: options.timestamp,
    message: {
      role: "toolResult",
      toolCallId: options.toolCallId,
      toolName: "read",
      isError: options.isError === true,
    },
  };
}

function given_skillLoadedEntry(timestamp: string, skillName: string): unknown {
  return {
    type: "custom",
    customType: "context:skill_loaded",
    timestamp,
    data: {
      name: skillName,
      path: `/Users/test/.config/ai/skills/${skillName}/SKILL.md`,
    },
  };
}

function given_tui() {
  return {
    requestRender() {},
  };
}

function given_theme() {
  return {
    fg(_color: string, text: string) {
      return text;
    },
  };
}

function given_mockPi() {
  const commands = new Map<string, { handler: Function }>();
  const sentMessages: Array<{ content: string; customType: string }> = [];

  return {
    pi: {
      registerCommand(name: string, command: { handler: Function }) {
        commands.set(name, command);
      },
      sendMessage(message: { content: string; customType: string }) {
        sentMessages.push(message);
      },
    },
    commands,
    sentMessages,
  };
}

async function when_parsingSkillSession(
  filePath: string,
): Promise<Map<string, Date>> {
  const actual = await parseSkillSessionFile(filePath);
  assert.ok(actual, "Expected a parsed skill session");
  return actual.skillFirstLoadedAt;
}

async function when_computingBreakdown(
  root: string,
  now: Date,
  options?: {
    globalUserSkillRoot?: string | null;
  },
) {
  return computeSkillBreakdown({
    root,
    now,
    globalUserSkillRoot: options?.globalUserSkillRoot ?? null,
  });
}

async function when_runningNonInteractiveCommand(
  commandHandler: Function,
  ctx: unknown,
): Promise<void> {
  await commandHandler("", ctx);
}

test("parseSkillSessionFile GIVEN successful skill reads and repeated context entries WHEN parsing THEN each skill keeps the first successful timestamp per session", async (t) => {
  const tempDirectory = given_tempDirectory(t);
  const filePath = given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-10T08-00-00-000Z_demo.jsonl",
    entries: [
      given_readAssistantMessage("2026-04-10T09:00:00.000Z", [
        { id: "call-napkin", skillName: "napkin" },
        { id: "call-jira", skillName: "jira" },
      ]),
      given_readToolResultMessage({
        timestamp: "2026-04-10T09:00:01.000Z",
        toolCallId: "call-napkin",
      }),
      given_readToolResultMessage({
        timestamp: "2026-04-10T09:00:02.000Z",
        toolCallId: "call-jira",
        isError: true,
      }),
      given_skillLoadedEntry("2026-04-10T09:00:03.000Z", "napkin"),
      given_skillLoadedEntry("2026-04-10T09:00:04.000Z", "clear-writing"),
      given_skillLoadedEntry("2026-04-10T09:00:05.000Z", "clear-writing"),
    ],
  });

  const actual = await when_parsingSkillSession(filePath);
  const expected = new Map([
    ["napkin", new Date("2026-04-10T09:00:01.000Z")],
    ["clear-writing", new Date("2026-04-10T09:00:04.000Z")],
  ]);

  assert.deepEqual(actual, expected);
});

test("computeSkillBreakdown GIVEN an old session file with recent skill activity WHEN aggregating THEN recent skill timestamps still count in the active ranges", async (t) => {
  const tempDirectory = given_tempDirectory(t);
  const now = new Date("2026-04-11T12:00:00.000Z");

  given_sessionFile({
    root: tempDirectory,
    fileName: "2025-12-01T08-00-00-000Z_old-but-active.jsonl",
    modifiedAt: new Date("2026-04-09T08:00:00.000Z"),
    entries: [given_skillLoadedEntry("2026-04-09T08:00:00.000Z", "napkin")],
  });
  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-10T08-00-00-000Z_recent.jsonl",
    entries: [
      given_skillLoadedEntry("2026-04-10T08:00:00.000Z", "napkin"),
      given_skillLoadedEntry("2026-04-10T08:01:00.000Z", "clear-writing"),
    ],
  });
  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-03-20T08-00-00-000Z_month.jsonl",
    entries: [
      given_skillLoadedEntry("2026-03-20T08:00:00.000Z", "napkin"),
      given_skillLoadedEntry("2026-03-20T08:01:00.000Z", "jira"),
    ],
  });
  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-01-05T08-00-00-000Z_too-old.jsonl",
    modifiedAt: new Date("2026-01-05T08:01:00.000Z"),
    entries: [given_skillLoadedEntry("2026-01-05T08:00:00.000Z", "oracle")],
  });

  const actual = await when_computingBreakdown(tempDirectory, now);
  const range7 = actual.ranges.get(7);
  const range30 = actual.ranges.get(30);
  const range90 = actual.ranges.get(90);

  assert.ok(range7, "Expected a 7 day range");
  assert.ok(range30, "Expected a 30 day range");
  assert.ok(range90, "Expected a 90 day range");

  assert.equal(range7.totalInvocations, 3);
  assert.equal(range7.sessionCount, 2);
  assert.equal(range7.skillCounts.get("napkin"), 2);
  assert.equal(range30.totalInvocations, 5);
  assert.equal(range30.sessionCount, 3);
  assert.equal(range30.skillCounts.get("napkin"), 3);
  assert.equal(range30.skillCounts.get("clear-writing"), 1);
  assert.equal(range30.skillCounts.get("jira"), 1);
  assert.equal(range90.totalInvocations, 5);
  assert.equal(range90.skillCounts.has("oracle"), false);
  assert.deepEqual(actual.palette.orderedSkills.slice(0, 3), [
    "napkin",
    "clear-writing",
    "jira",
  ]);
});

test("SkillBreakdownComponent GIVEN an empty breakdown WHEN rendering initially THEN the 30 day range is selected by default", async (t) => {
  const tempDirectory = given_tempDirectory(t);
  const actualData = await when_computingBreakdown(
    tempDirectory,
    new Date("2026-04-11T12:00:00.000Z"),
  );
  const component = new SkillBreakdownComponent(
    actualData,
    given_tui() as never,
    () => {},
    given_theme(),
  );

  const actual = component.render(80).join("\n");

  assert.match(actual, /\[30d\]/);
  assert.doesNotMatch(actual, /\[7d\]/);
  assert.doesNotMatch(actual, /\[90d\]/);
});

test("SkillBreakdownComponent GIVEN more than ten skills WHEN rendering the skills view THEN it shows the top ten rows", async (t) => {
  const tempDirectory = given_tempDirectory(t);
  const now = new Date("2026-04-11T12:00:00.000Z");
  const skillNames = [
    "skill-a",
    "skill-b",
    "skill-c",
    "skill-d",
    "skill-e",
    "skill-f",
    "skill-g",
    "skill-h",
    "skill-i",
    "skill-j",
    "skill-k",
  ];

  skillNames.forEach((skillName, index) => {
    given_sessionFile({
      root: tempDirectory,
      fileName: `2026-04-${String(index + 1).padStart(2, "0")}T08-00-00-000Z_${skillName}.jsonl`,
      entries: Array.from({ length: skillNames.length - index }, () =>
        given_skillLoadedEntry(now.toISOString(), skillName),
      ),
    });
  });

  const actualData = await when_computingBreakdown(tempDirectory, now);
  const component = new SkillBreakdownComponent(
    actualData,
    given_tui() as never,
    () => {},
    given_theme(),
  );

  const actual = component.render(120).join("\n");

  assert.match(actual, /skill-a/);
  assert.match(actual, /skill-j/);
  assert.doesNotMatch(actual, /skill-k/);
});

test("SkillBreakdownComponent GIVEN a numeric search query WHEN confirming with slash search THEN it jumps to the matching skill summary", async (t) => {
  const tempDirectory = given_tempDirectory(t);
  const now = new Date("2026-04-11T12:00:00.000Z");

  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-10T08-00-00-000Z_alpha.jsonl",
    entries: [given_skillLoadedEntry("2026-04-10T08:00:00.000Z", "alpha")],
  });
  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-10T09-00-00-000Z_beta-1.jsonl",
    entries: [given_skillLoadedEntry("2026-04-10T09:00:00.000Z", "beta")],
  });
  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-10T10-00-00-000Z_beta-2.jsonl",
    entries: [given_skillLoadedEntry("2026-04-10T10:00:00.000Z", "beta")],
  });

  const actualData = await when_computingBreakdown(tempDirectory, now);
  const component = new SkillBreakdownComponent(
    actualData,
    given_tui() as never,
    () => {},
    given_theme(),
  );

  component.handleInput("/");
  component.handleInput("2");
  component.handleInput("\r");

  const actual = component.render(120).join("\n");

  assert.match(actual, /skill: beta/i);
  assert.match(actual, /scope: all models/i);
});

test("SkillBreakdownComponent GIVEN a selected skill WHEN toggling the project model scope THEN it renders per-project counts for the active model", async (t) => {
  const tempDirectory = given_tempDirectory(t);
  const now = new Date("2026-04-11T12:00:00.000Z");

  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-09T08-00-00-000Z_project-a-alpha.jsonl",
    entries: [
      given_sessionStartEntry("2026-04-09T08:00:00.000Z", "/work/project-a"),
      given_readAssistantMessage("2026-04-09T08:00:01.000Z", [
        { id: "call-a-alpha", skillName: "jira", model: "model-alpha" },
      ]),
      given_readToolResultMessage({
        timestamp: "2026-04-09T08:00:02.000Z",
        toolCallId: "call-a-alpha",
      }),
    ],
  });
  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-09T09-00-00-000Z_project-a-beta.jsonl",
    entries: [
      given_sessionStartEntry("2026-04-09T09:00:00.000Z", "/work/project-a"),
      given_readAssistantMessage("2026-04-09T09:00:01.000Z", [
        { id: "call-a-beta", skillName: "jira", model: "model-beta" },
      ]),
      given_readToolResultMessage({
        timestamp: "2026-04-09T09:00:02.000Z",
        toolCallId: "call-a-beta",
      }),
    ],
  });
  given_sessionFile({
    root: tempDirectory,
    fileName: "2026-04-09T10-00-00-000Z_project-b-alpha.jsonl",
    entries: [
      given_sessionStartEntry("2026-04-09T10:00:00.000Z", "/work/project-b"),
      given_readAssistantMessage("2026-04-09T10:00:01.000Z", [
        { id: "call-b-alpha", skillName: "jira", model: "model-alpha" },
      ]),
      given_readToolResultMessage({
        timestamp: "2026-04-09T10:00:02.000Z",
        toolCallId: "call-b-alpha",
      }),
    ],
  });

  const actualData = await when_computingBreakdown(tempDirectory, now);
  const component = new SkillBreakdownComponent(
    actualData,
    given_tui() as never,
    () => {},
    given_theme(),
  );

  component.handleInput("/");
  component.handleInput("j");
  component.handleInput("i");
  component.handleInput("r");
  component.handleInput("a");
  component.handleInput("\r");

  const globalActual = component.render(120).join("\n");
  assert.match(globalActual, /skill: jira/i);
  assert.match(globalActual, /scope: all models/i);
  assert.match(globalActual, /project-a/i);
  assert.match(globalActual, /project-b/i);

  component.handleInput("\t");
  const alphaActual = component.render(120).join("\n");
  assert.match(alphaActual, /scope: test\/model-alpha/i);
  assert.match(alphaActual, /project-a/i);
  assert.match(alphaActual, /project-b/i);

  component.handleInput("\t");
  const betaActual = component.render(120).join("\n");
  assert.match(betaActual, /scope: test\/model-beta/i);
  assert.match(betaActual, /project-a/i);
  assert.doesNotMatch(betaActual, /project-b\b.*\b1\b/i);
});

test("extension GIVEN non-interactive mode WHEN running the command THEN it sends a 30 day breakdown with the top ten skills", async (t) => {
  const tempHome = given_tempHome(t);
  const sessionRoot = path.join(tempHome, ".pi", "agent", "sessions");
  const now = new Date();
  const isoDate = (daysAgo: number) => {
    const date = new Date(now);
    date.setDate(date.getDate() - daysAgo);
    return date.toISOString();
  };
  const fileStamp = (daysAgo: number, suffix: string) => {
    const date = new Date(now);
    date.setDate(date.getDate() - daysAgo);
    const stamp = date.toISOString().replace(/[:.]/g, "-");
    return `${stamp}_${suffix}.jsonl`;
  };

  const skillNames = [
    "skill-a",
    "skill-b",
    "skill-c",
    "skill-d",
    "skill-e",
    "skill-f",
    "skill-g",
    "skill-h",
    "skill-i",
    "skill-j",
    "skill-k",
  ];

  skillNames.forEach((skillName, index) => {
    given_sessionFile({
      root: sessionRoot,
      fileName: fileStamp(index, `skill-${index}`),
      entries: Array.from({ length: skillNames.length - index }, () =>
        given_skillLoadedEntry(isoDate(index), skillName),
      ),
    });
  });

  const { pi, commands, sentMessages } = given_mockPi();
  skillBreakdownExtension(pi as never);

  const command = commands.get("cmd:skill-breakdown");
  assert.ok(command, "Expected /cmd:skill-breakdown to be registered");

  await when_runningNonInteractiveCommand(command.handler, { hasUI: false });

  assert.equal(sentMessages.length, 1);

  const actual = sentMessages[0]?.content ?? "";
  assert.match(actual, /Last 30 days:/);
  assert.match(actual, /skill-a/);
  assert.match(actual, /skill-j/);
  assert.doesNotMatch(actual, /skill-k/);
});
