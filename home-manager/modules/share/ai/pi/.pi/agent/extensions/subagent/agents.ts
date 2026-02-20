/**
 * Agent discovery and configuration
 */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { parseFrontmatter } from "@mariozechner/pi-coding-agent";

export interface AgentConfig {
  name: string;
  description: string;
  tools?: string[];
  model?: string;
  systemPrompt: string;
  /** Resolved absolute path of the source directory */
  source: string;
  filePath: string;
}

export interface AgentDiscoveryResult {
  agents: AgentConfig[];
}

/** Expands ~ or $HOME prefix and returns an absolute path, resolving relative paths against cwd. */
export function resolvePath(p: string, cwd: string): string {
  const home = os.homedir();
  let expanded = p;
  if (expanded.startsWith("~/")) {
    expanded = path.join(home, expanded.slice(2));
  } else if (expanded === "~") {
    expanded = home;
  } else if (expanded.startsWith("$HOME/")) {
    expanded = path.join(home, expanded.slice(6));
  } else if (expanded === "$HOME") {
    expanded = home;
  }
  return path.isAbsolute(expanded) ? expanded : path.resolve(cwd, expanded);
}

function loadAgentsFromDir(dir: string): AgentConfig[] {
  const agents: AgentConfig[] = [];

  if (!fs.existsSync(dir)) {
    return agents;
  }

  let entries: fs.Dirent[];
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return agents;
  }

  for (const entry of entries) {
    if (!entry.name.endsWith(".md")) continue;
    if (!entry.isFile() && !entry.isSymbolicLink()) continue;

    const filePath = path.join(dir, entry.name);
    let content: string;
    try {
      content = fs.readFileSync(filePath, "utf-8");
    } catch {
      continue;
    }

    const { frontmatter, body } =
      parseFrontmatter<Record<string, string>>(content);

    if (!frontmatter.name || !frontmatter.description) {
      continue;
    }

    const tools = frontmatter.tools
      ?.split(",")
      .map((t: string) => t.trim())
      .filter(Boolean);

    agents.push({
      name: frontmatter.name,
      description: frontmatter.description,
      tools: tools && tools.length > 0 ? tools : undefined,
      model: frontmatter.model,
      systemPrompt: body,
      source: dir,
      filePath,
    });
  }

  return agents;
}

/**
 * Discover agents from an ordered list of source directories.
 * Paths can be absolute (with ~ / $HOME expansion) or relative to cwd.
 * Later sources override earlier ones on name collision.
 */
export function discoverAgents(
  sources: string[],
  cwd: string,
): AgentDiscoveryResult {
  const agentMap = new Map<string, AgentConfig>();

  for (const rawSource of sources) {
    const resolvedDir = resolvePath(rawSource, cwd);
    for (const agent of loadAgentsFromDir(resolvedDir)) {
      agentMap.set(agent.name, agent);
    }
  }

  return { agents: Array.from(agentMap.values()) };
}
