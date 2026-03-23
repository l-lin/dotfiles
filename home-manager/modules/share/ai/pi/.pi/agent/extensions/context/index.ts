/**
 * /context
 *
 * Small TUI view showing what's loaded/available:
 * - extensions (best-effort from registered extension slash commands)
 * - skills
 * - project context files (AGENTS.md / CLAUDE.md)
 * - current context window usage + session totals (tokens/cost)
 *
 * Dependencies:
 * - ../subagent
 *
 * src: https://github.com/mitsuhiko/agent-stuff/blob/7e67a9684f066435dd996a5b98c6850ecf3c8c6d/pi-extensions/context.ts
 */

import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionContext,
  ToolResultEvent,
} from "@mariozechner/pi-coding-agent";
import path from "node:path";
import { loadSettings } from "../subagent/settings.js";
import { discoverAgents } from "../subagent/agents.js";
import type { ContextViewData, SkillIndexEntry } from "./types.js";
import { SKILL_LOADED_ENTRY } from "./types.js";
import {
  estimateTokens,
  normalizeReadPath,
  normalizeSkillName,
  shortenPath,
} from "./utils.js";
import { buildSkillIndex, loadProjectContextFiles } from "./loaders.js";
import {
  getLoadedSkillsFromSession,
  matchSkillForPath,
  sumSessionUsage,
} from "./session.js";
import { ContextView, makePlainTextView } from "./view.js";

export default function contextExtension(pi: ExtensionAPI) {
  let lastSessionId: string | null = null;
  let cachedLoadedSkills = new Set<string>();
  let cachedSkillIndex: SkillIndexEntry[] = [];

  const ensureCaches = (ctx: ExtensionContext) => {
    const sid = ctx.sessionManager.getSessionId();
    if (sid !== lastSessionId) {
      lastSessionId = sid;
      cachedLoadedSkills = getLoadedSkillsFromSession(ctx);
      cachedSkillIndex = buildSkillIndex(pi, ctx.cwd);
    }
    if (cachedSkillIndex.length === 0) {
      cachedSkillIndex = buildSkillIndex(pi, ctx.cwd);
    }
  };

  pi.on("tool_result", (event: ToolResultEvent, ctx: ExtensionContext) => {
    const evt = event as any;
    if (evt.toolName !== "read" || evt.isError) return;

    const filePath = evt.input?.path;
    if (typeof filePath !== "string") return;

    ensureCaches(ctx);

    const absolutePath = normalizeReadPath(filePath, ctx.cwd);
    const skillName = matchSkillForPath(absolutePath, cachedSkillIndex);

    if (skillName && !cachedLoadedSkills.has(skillName)) {
      cachedLoadedSkills.add(skillName);
      pi.appendEntry(SKILL_LOADED_ENTRY, {
        name: skillName,
        path: absolutePath,
      });
    }
  });

  pi.registerCommand("cmd:context", {
    description: "Show loaded context overview",
    handler: async (_args, ctx: ExtensionCommandContext) => {
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
        .map((p) => (p === "<unknown>" ? p : path.basename(p)))
        .sort((a, b) => a.localeCompare(b));

      const skills = skillCmds
        .map((c) => normalizeSkillName(c.name))
        .sort((a, b) => a.localeCompare(b));

      const skillDescTokens = skillCmds.reduce((acc, c) => {
        const blob = c.description
          ? `${normalizeSkillName(c.name)}\n${c.description}`
          : normalizeSkillName(c.name);
        return acc + estimateTokens(blob);
      }, 0);

      const agentFiles = await loadProjectContextFiles(ctx.cwd);
      const agentFilesWithTokens = agentFiles.map((f) => ({
        path: shortenPath(f.path, ctx.cwd),
        tokens: f.tokens,
      }));

      const systemPrompt = ctx.getSystemPrompt();
      const systemPromptTokens = systemPrompt
        ? estimateTokens(systemPrompt)
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
        toolsTokens += estimateTokens(blob);
      }
      toolsTokens = Math.round(toolsTokens * TOOL_FUDGE);

      const effectiveTokens = messageTokens + toolsTokens;
      const percent = ctxWindow > 0 ? (effectiveTokens / ctxWindow) * 100 : 0;
      const remainingTokens =
        ctxWindow > 0 ? Math.max(0, ctxWindow - effectiveTokens) : 0;

      const sessionUsage = sumSessionUsage(ctx);

      const subagentConfig = loadSettings();
      const { agents: discoveredAgents } = discoverAgents(
        subagentConfig.sources,
        ctx.cwd,
      );
      const subagents = discoveredAgents
        .map((a) => a.name)
        .sort((a, b) => a.localeCompare(b));

      const loadedSkills = Array.from(getLoadedSkillsFromSession(ctx)).sort(
        (a, b) => a.localeCompare(b),
      );

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
        subagents,
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
            content: makePlainTextView(viewData),
            display: true,
          },
          { triggerTurn: false },
        );
        return;
      }

      await ctx.ui.custom<void>(
        (_tui, theme, _kb, done) => {
          return new ContextView(theme, viewData, done);
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
