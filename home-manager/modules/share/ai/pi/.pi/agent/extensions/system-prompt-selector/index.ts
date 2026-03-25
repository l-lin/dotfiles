/**
 * System Prompt Selector — Switch the system prompt via /system
 *
 * Scans .pi/agents/, .claude/agents/, .gemini/agents/, .codex/agents/
 * (project-local and global) for agent definition .md files.
 *
 * /system opens a select dialog to pick a system prompt. The selected
 * agent's body is prepended to Pi's default instructions so tool usage
 * still works. Tools are restricted to the agent's declared tool set
 * if specified.
 *
 * Dependencies:
 * - ./subagent/
 *
 * src: https://github.com/disler/pi-vs-claude-code/blob/32dfe122cb6d444e91c68b32597274a725d81fa3/extensions/system-select.ts
 * Adapted to load subagents from my own subagent config + change display.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { readdirSync, readFileSync, existsSync } from "node:fs";
import { join, basename, isAbsolute, resolve } from "node:path";
import { homedir } from "node:os";
import { loadSettings } from "../subagent/settings.js";

interface AgentDef {
  name: string;
  description: string;
  tools: string[];
  body: string;
  source: string;
}

function parseFrontmatter(raw: string): {
  fields: Record<string, string>;
  body: string;
} {
  const match = raw.match(/^---\s*\n([\s\S]*?)\n---\s*\n([\s\S]*)$/);
  if (!match) return { fields: {}, body: raw };
  const fields: Record<string, string> = {};
  for (const line of match[1].split("\n")) {
    const idx = line.indexOf(":");
    if (idx > 0) fields[line.slice(0, idx).trim()] = line.slice(idx + 1).trim();
  }
  return { fields, body: match[2] };
}

function scanAgents(dir: string, source: string): AgentDef[] {
  if (!existsSync(dir)) return [];
  const agents: AgentDef[] = [];
  try {
    for (const file of readdirSync(dir)) {
      if (!file.endsWith(".md")) continue;
      const raw = readFileSync(join(dir, file), "utf-8");
      const { fields, body } = parseFrontmatter(raw);
      agents.push({
        name: fields.name || basename(file, ".md"),
        description: fields.description || "",
        tools: fields.tools ? fields.tools.split(",").map((t) => t.trim()) : [],
        body: body.trim(),
        source,
      });
    }
  } catch {}
  return agents;
}

function displayName(name: string): string {
  return name
    .split("-")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
}

function bold(s: string): string {
  return `\x1b[1m${s}\x1b[22m`;
}

function clip(s: string, max: number): string {
  return s.length > max ? s.slice(0, max - 1) + "\u2026" : s;
}

export default function (pi: ExtensionAPI) {
  let activeAgent: AgentDef | null = null;
  let allAgents: AgentDef[] = [];
  let defaultTools: string[] = [];

  pi.on("session_start", async (_event, ctx) => {
    activeAgent = null;
    allAgents = [];

    const home = homedir();
    const cwd = ctx.cwd;

    const { sources } = loadSettings();
    const dirs: [string, string][] = sources.map((src) => {
      const expanded = src.replace(/^~/, home).replace(/^\$HOME/, home);
      const absolute = isAbsolute(expanded) ? expanded : resolve(cwd, expanded);
      return [absolute, src];
    });

    const seen = new Set<string>();
    const sourceCounts: Record<string, number> = {};

    for (const [dir, source] of dirs) {
      const agents = scanAgents(dir, source);
      for (const agent of agents) {
        const key = agent.name.toLowerCase();
        if (seen.has(key)) continue;
        seen.add(key);
        allAgents.push(agent);
        sourceCounts[source] = (sourceCounts[source] || 0) + 1;
      }
    }

    defaultTools = pi.getActiveTools();
  });

  pi.registerCommand("cmd:system-prompt", {
    description: "Select a system prompt from discovered agents",
    handler: async (_args, ctx) => {
      if (allAgents.length === 0) {
        ctx.ui.notify("No agents found", "warning");
        return;
      }

      const NAME_MAX = 20;
      const DESC_MAX = 60;

      const displayNames = allAgents.map((a) => displayName(a.name));
      const nameColWidth = Math.min(
        Math.max(...displayNames.map((n) => n.length)),
        NAME_MAX,
      );

      const options = [
        " Reset to Default",
        ...allAgents.map((a, i) => {
          const name = clip(displayNames[i], nameColWidth).padEnd(nameColWidth);
          const desc = clip(a.description || "", DESC_MAX).padEnd(DESC_MAX);
          return `◆ ${bold(name)}  ·  ${desc}  (${a.source})`;
        }),
      ];

      const choice = await ctx.ui.select("Select System Prompt", options);
      if (choice === undefined) return;

      if (choice === options[0]) {
        activeAgent = null;
        pi.setActiveTools(defaultTools);
        ctx.ui.setStatus("system-prompt", undefined);
        ctx.ui.notify("System Prompt reset to 'Default'", "info");
        return;
      }

      const idx = options.indexOf(choice) - 1;
      const agent = allAgents[idx];
      activeAgent = agent;

      if (agent.tools.length > 0) {
        pi.setActiveTools(agent.tools);
      } else {
        pi.setActiveTools(defaultTools);
      }

      ctx.ui.setStatus("system-prompt", ` ${displayName(agent.name)}`);
      ctx.ui.notify(
        `System Prompt switched to: ${displayName(agent.name)}`,
        "info",
      );
    },
  });

  pi.on("before_agent_start", async (_event, _ctx) => {
    if (!activeAgent) return;
    return {
      systemPrompt: activeAgent.body,
    };
  });
}
