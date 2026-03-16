import os from "node:os";
import path from "node:path";

export function formatUsd(cost: number): string {
  if (!Number.isFinite(cost) || cost <= 0) return "$0.00";
  if (cost >= 1) return `$${cost.toFixed(2)}`;
  if (cost >= 0.1) return `$${cost.toFixed(3)}`;
  return `$${cost.toFixed(4)}`;
}

export function estimateTokens(text: string): number {
  return Math.max(0, Math.ceil(text.length / 4));
}

export function normalizeReadPath(inputPath: string, cwd: string): string {
  let p = inputPath;
  if (p.startsWith("@")) p = p.slice(1);
  if (p === "~") p = os.homedir();
  else if (p.startsWith("~/")) p = path.join(os.homedir(), p.slice(2));
  if (!path.isAbsolute(p)) p = path.resolve(cwd, p);
  return path.resolve(p);
}

function expandHomePath(p: string): string {
  if (p === "~") return os.homedir();
  if (p.startsWith("~/")) return path.join(os.homedir(), p.slice(2));
  return p;
}

export function getAgentDir(): string {
  const exactMatch = process.env["PI_CODING_AGENT_DIR"];
  if (exactMatch) return expandHomePath(exactMatch);

  for (const [key, value] of Object.entries(process.env)) {
    if (key.endsWith("_CODING_AGENT_DIR") && value) {
      return expandHomePath(value);
    }
  }

  return path.join(os.homedir(), ".pi", "agent");
}

export function shortenPath(p: string, cwd: string): string {
  const rp = path.resolve(p);
  const rc = path.resolve(cwd);
  if (rp === rc) return ".";
  if (rp.startsWith(rc + path.sep)) return "./" + rp.slice(rc.length + 1);
  return rp;
}

export function normalizeSkillName(name: string): string {
  return name.startsWith("skill:") ? name.slice("skill:".length) : name;
}

export function joinComma(items: string[]): string {
  return items.join(", ");
}
