// ============================================================================
// GitHub Copilot Extension — OAuth Token Reader
// ============================================================================

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import type { AuthStatus } from "./types.js";

function getTokenPaths(): string[] {
  // Windows: GitHub Copilot stores config in %APPDATA% (Roaming), not LocalAppData.
  const configDir =
    process.env.XDG_CONFIG_HOME ||
    (process.platform === "win32"
      ? process.env.APPDATA || path.join(os.homedir(), "AppData", "Roaming")
      : path.join(os.homedir(), ".config"));

  return [
    path.join(configDir, "github-copilot/hosts.json"),
    path.join(configDir, "github-copilot/apps.json"),
  ];
}

export function getOAuthToken(): AuthStatus {
  if (process.env.GITHUB_TOKEN) {
    return { hasToken: true, token: process.env.GITHUB_TOKEN };
  }

  for (const filePath of getTokenPaths()) {
    try {
      if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, "utf-8");
        const data = JSON.parse(content);
        for (const [key, value] of Object.entries(data)) {
          if (key.includes("github.com") && (value as any).oauth_token) {
            return { hasToken: true, token: (value as any).oauth_token };
          }
        }
      }
    } catch {
      // Try next file
    }
  }

  return {
    hasToken: false,
    error:
      "No Copilot token found. Install GitHub Copilot in your editor first.",
  };
}
