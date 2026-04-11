import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { matchesKey, type KeyId } from "@mariozechner/pi-tui";
import type { KeybindingsManager } from "@mariozechner/pi-coding-agent";
import { computeSkillBreakdown } from "./aggregation.js";
import type { SkillBreakdownData } from "./types.js";

type TestContextLike = {
  after(callback: () => void): void;
};

export function given_tempDirectory(t: TestContextLike): string {
  const tempDirectory = fs.mkdtempSync(
    path.join(os.tmpdir(), "skill-breakdown-"),
  );

  t.after(() => {
    fs.rmSync(tempDirectory, { recursive: true, force: true });
  });

  return tempDirectory;
}

export function given_tempHome(t: TestContextLike): string {
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

export function given_sessionFile(options: {
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

export function given_sessionStartEntry(
  timestamp: string,
  cwd: string,
): unknown {
  return {
    type: "session",
    timestamp,
    cwd,
  };
}

export function given_readAssistantMessage(
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

export function given_readToolResultMessage(options: {
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

export function given_skillLoadedEntry(
  timestamp: string,
  skillName: string,
): unknown {
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

export function given_tui() {
  return {
    requestRender() {},
  };
}

export function given_theme() {
  return {
    fg(_color: string, text: string) {
      return text;
    },
  };
}

export function given_keybindings(
  overrides?: Record<string, string | string[]>,
) {
  const bindings = new Map<string, KeyId[]>([
    ["tui.select.up", ["up"]],
    ["tui.select.down", ["down"]],
    ["tui.select.confirm", ["enter"]],
    ["tui.select.cancel", ["escape"]],
  ]);

  for (const [binding, keys] of Object.entries(overrides ?? {})) {
    bindings.set(binding, (Array.isArray(keys) ? keys : [keys]) as KeyId[]);
  }

  return {
    matches(data: string, binding: string) {
      const keys = bindings.get(binding) ?? [];
      return keys.some((key) => data === key || matchesKey(data, key));
    },
  } as Pick<KeybindingsManager, "matches">;
}

export function given_mockPi() {
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

export async function when_computingBreakdown(
  root: string,
  now: Date,
  options?: {
    globalUserSkillRoot?: string | null;
  },
): Promise<SkillBreakdownData> {
  return computeSkillBreakdown({
    root,
    now,
    globalUserSkillRoot: options?.globalUserSkillRoot ?? null,
  });
}

export function then_expectParsedSession(actual: unknown): asserts actual {
  assert.ok(actual, "Expected a parsed skill session");
}
