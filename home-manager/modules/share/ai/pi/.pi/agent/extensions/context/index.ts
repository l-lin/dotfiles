/**
 * /context
 *
 * Small TUI view showing what's loaded/available:
 * - extensions (best-effort from registered extension slash commands)
 * - skills
 * - project context files (AGENTS.md / CLAUDE.md)
 * - current context window usage + session totals (tokens/cost)
 *
 * src: https://github.com/mitsuhiko/agent-stuff/blob/7e67a9684f066435dd996a5b98c6850ecf3c8c6d/pi-extensions/context.ts
 */

import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionContext,
  ToolResultEvent,
} from "@earendil-works/pi-coding-agent";
import path from "node:path";
import type { ContextViewData, SkillIndexEntry } from "./types.js";

const SKILL_LOADED_ENTRY = "context:skill_loaded";

type ContextRuntime = {
  estimateTokens: (typeof import("./utils.js"))["estimateTokens"];
  normalizeReadPath: (typeof import("./utils.js"))["normalizeReadPath"];
  normalizeSkillName: (typeof import("./utils.js"))["normalizeSkillName"];
  shortenPath: (typeof import("./utils.js"))["shortenPath"];
  buildSkillIndex: (typeof import("./loaders.js"))["buildSkillIndex"];
  loadProjectContextFiles: (typeof import("./loaders.js"))["loadProjectContextFiles"];
  getLoadedSkillsFromSession: (typeof import("./session.js"))["getLoadedSkillsFromSession"];
  matchSkillForPath: (typeof import("./session.js"))["matchSkillForPath"];
  sumSessionUsage: (typeof import("./session.js"))["sumSessionUsage"];
  ContextView: (typeof import("./view.js"))["ContextView"];
  makePlainTextView: (typeof import("./view.js"))["makePlainTextView"];
};

let runtimePromise: Promise<ContextRuntime> | undefined;

function loadRuntime(): Promise<ContextRuntime> {
  if (runtimePromise) return runtimePromise;

  const loading = Promise.all([
    import("./utils.js"),
    import("./loaders.js"),
    import("./session.js"),
    import("./view.js"),
  ]).then(([utils, loaders, session, view]) => ({
    estimateTokens: utils.estimateTokens,
    normalizeReadPath: utils.normalizeReadPath,
    normalizeSkillName: utils.normalizeSkillName,
    shortenPath: utils.shortenPath,
    buildSkillIndex: loaders.buildSkillIndex,
    loadProjectContextFiles: loaders.loadProjectContextFiles,
    getLoadedSkillsFromSession: session.getLoadedSkillsFromSession,
    matchSkillForPath: session.matchSkillForPath,
    sumSessionUsage: session.sumSessionUsage,
    ContextView: view.ContextView,
    makePlainTextView: view.makePlainTextView,
  }));

  runtimePromise = loading.catch((error) => {
    runtimePromise = undefined;
    throw error;
  });
  return runtimePromise;
}

function formatExtensionName(sourcePath: string): string {
  if (sourcePath === "<unknown>") return sourcePath;

  const baseName = path.basename(sourcePath);
  if (/^index\.[cm]?[jt]sx?$/i.test(baseName)) {
    const parentName = path.basename(path.dirname(sourcePath));
    return parentName || baseName;
  }

  return baseName;
}

export default function contextExtension(pi: ExtensionAPI) {
  let lastSessionId: string | null = null;
  let cachedLoadedSkills = new Set<string>();
  let cachedSkillIndex: SkillIndexEntry[] = [];

  const ensureCaches = async (
    ctx: ExtensionContext,
    runtime: ContextRuntime,
  ) => {
    const sid = ctx.sessionManager.getSessionId();
    if (sid !== lastSessionId) {
      lastSessionId = sid;
      cachedLoadedSkills = runtime.getLoadedSkillsFromSession(ctx);
      cachedSkillIndex = runtime.buildSkillIndex(pi, ctx.cwd);
    }
    if (cachedSkillIndex.length === 0) {
      cachedSkillIndex = runtime.buildSkillIndex(pi, ctx.cwd);
    }
  };

  pi.on(
    "tool_result",
    async (event: ToolResultEvent, ctx: ExtensionContext) => {
      if (event.toolName !== "read" || event.isError) return;

      const filePath = event.input?.path;
      if (typeof filePath !== "string") return;

      const runtime = await loadRuntime();
      await ensureCaches(ctx, runtime);

      const absolutePath = runtime.normalizeReadPath(filePath, ctx.cwd);
      const skillName = runtime.matchSkillForPath(
        absolutePath,
        cachedSkillIndex,
      );

      if (skillName && !cachedLoadedSkills.has(skillName)) {
        cachedLoadedSkills.add(skillName);
        pi.appendEntry(SKILL_LOADED_ENTRY, {
          name: skillName,
          path: absolutePath,
        });
      }
    },
  );

  pi.registerCommand("cmd:context", {
    description: "Show loaded context overview",
    handler: async (_args, ctx: ExtensionCommandContext) => {
      const runtime = await loadRuntime();
      const commands = pi.getCommands();
      const extensionCmds = commands.filter((c) => c.source === "extension");
      const skillCmds = commands.filter((c) => c.source === "skill");

      const extensionsByPath = new Map<string, string[]>();
      for (const command of extensionCmds) {
        const commandPath = command.sourceInfo.path ?? "<unknown>";
        const namesAtPath = extensionsByPath.get(commandPath) ?? [];
        namesAtPath.push(command.name);
        extensionsByPath.set(commandPath, namesAtPath);
      }
      const extensionFiles = [...extensionsByPath.keys()]
        .map(formatExtensionName)
        .sort((a, b) => a.localeCompare(b));

      const skills = skillCmds
        .map((c) => runtime.normalizeSkillName(c.name))
        .sort((a, b) => a.localeCompare(b));

      const skillDescTokens = skillCmds.reduce((acc, c) => {
        const blob = c.description
          ? `${runtime.normalizeSkillName(c.name)}\n${c.description}`
          : runtime.normalizeSkillName(c.name);
        return acc + runtime.estimateTokens(blob);
      }, 0);

      const agentFiles = await runtime.loadProjectContextFiles(ctx.cwd);
      const agentFilesWithTokens = agentFiles.map((f) => ({
        path: runtime.shortenPath(f.path, ctx.cwd),
        tokens: f.tokens,
      }));

      const systemPrompt = ctx.getSystemPrompt();
      const systemPromptTokens = systemPrompt
        ? runtime.estimateTokens(systemPrompt)
        : 0;

      const usage = ctx.getContextUsage();
      const messageTokens = usage?.tokens ?? 0;
      const ctxWindow = usage?.contextWindow ?? 0;

      const TOOL_FUDGE = 1.5;
      const activeToolNames = pi.getActiveTools();
      const toolInfoByName = new Map(
        pi.getAllTools().map((t) => [t.name, t] as const),
      );
      let toolsTokens = 0;
      for (const name of activeToolNames) {
        const info = toolInfoByName.get(name);
        const blob = `${name}\n${info?.description ?? ""}`;
        toolsTokens += runtime.estimateTokens(blob);
      }
      toolsTokens = Math.round(toolsTokens * TOOL_FUDGE);

      const effectiveTokens = messageTokens + toolsTokens;
      const percent = ctxWindow > 0 ? (effectiveTokens / ctxWindow) * 100 : 0;
      const remainingTokens =
        ctxWindow > 0 ? Math.max(0, ctxWindow - effectiveTokens) : 0;

      const sessionUsage = runtime.sumSessionUsage(ctx);

      const loadedSkills = Array.from(
        runtime.getLoadedSkillsFromSession(ctx),
      ).sort((a, b) => a.localeCompare(b));

      const viewData: ContextViewData = {
        usage: usage
          ? {
              messageTokens,
              contextWindow: ctxWindow,
              effectiveTokens,
              percent,
              remainingTokens,
              systemPromptTokens,
              toolsTokens,
              activeTools: activeToolNames.length,
            }
          : null,
        agentFiles: agentFilesWithTokens,
        extensions: extensionFiles,
        skills,
        skillDescTokens,
        loadedSkills,
        activeToolNames,
        session: {
          totalTokens: sessionUsage.totalTokens,
          totalCost: sessionUsage.totalCost,
        },
      };

      if (!ctx.hasUI) {
        pi.sendMessage(
          {
            customType: "context",
            content: runtime.makePlainTextView(viewData),
            display: true,
          },
          { triggerTurn: false },
        );
        return;
      }

      await ctx.ui.custom<void>(
        (_tui, theme, _kb, done) => {
          return new runtime.ContextView(theme, viewData, done);
        },
        {
          overlay: true,
          overlayOptions: {
            anchor: "center",
            width: "50%",
            minWidth: 60,
            maxHeight: "85%",
          },
        },
      );
    },
  });
}
