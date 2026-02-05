/**
 * GitHub Copilot Premium Request Usage Extension
 *
 * Displays Copilot premium request usage in a widget:
 * - Progress bar with used/max requests and percentage
 * - Reset date in YYYY-MM-DD format
 * - Days remaining until quota reset
 *
 * Reads OAuth token from ~/.config/github-copilot/apps.json or hosts.json
 * Uses the internal GitHub Copilot API.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

// ============================================================================
// Types
// ============================================================================

interface CopilotUserResponse {
  access_type_sku: string;
  copilot_plan: string;
  quota_reset_date: string;
  quota_snapshots?: {
    premium_interactions?: {
      entitlement: number;
      remaining: number;
      unlimited: boolean;
      percent_remaining: number;
      overage_permitted: boolean;
      overage_count: number;
    };
    chat?: {
      entitlement: number;
      remaining: number;
      unlimited: boolean;
    };
    completions?: {
      entitlement: number;
      remaining: number;
      unlimited: boolean;
    };
  };
  // For limited/free users
  limited_user_quotas?: {
    chat: number;
    completions: number;
  };
  limited_user_reset_date?: string;
  monthly_quotas?: {
    chat: number;
    completions: number;
  };
}

interface UsageData {
  used: number;
  quota: number;
  remaining: number;
  resetDate: string;
  unlimited: boolean;
  overagePermitted: boolean;
  plan: string;
}

interface AuthStatus {
  hasToken: boolean;
  token?: string;
  error?: string;
}

const WIDGET_ID = "copilot-usage";
const BAR_WIDTH = 20;
const WIDGET_PLACEMENT = { placement: "aboveEditor" };
const SETTINGS_PATH = path.join(os.homedir(), ".pi/agent/settings.json");

// ============================================================================
// Settings
// ============================================================================

interface PiSettings {
  copilotUsageVisible?: boolean;
}

function loadSettings(): PiSettings {
  try {
    if (fs.existsSync(SETTINGS_PATH)) {
      const content = fs.readFileSync(SETTINGS_PATH, "utf-8");
      return JSON.parse(content) as PiSettings;
    }
  } catch {
    // Ignore errors, return defaults
  }
  return {};
}

// Token file locations (same as codecompanion.nvim)
function getTokenPaths(): string[] {
  const configDir =
    process.env.XDG_CONFIG_HOME ||
    (process.platform === "win32"
      ? path.join(os.homedir(), "AppData/Local")
      : path.join(os.homedir(), ".config"));

  return [
    path.join(configDir, "github-copilot/hosts.json"),
    path.join(configDir, "github-copilot/apps.json"),
  ];
}

// ============================================================================
// OAuth Token
// ============================================================================

function getOAuthToken(): AuthStatus {
  // Check environment variable first (for Codespaces)
  const envToken = process.env.GITHUB_TOKEN;
  const isCodespaces = process.env.CODESPACES;
  if (envToken && isCodespaces) {
    return { hasToken: true, token: envToken };
  }

  // Check config files
  for (const filePath of getTokenPaths()) {
    try {
      if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, "utf-8");
        const data = JSON.parse(content);

        // Find github.com entry
        for (const [key, value] of Object.entries(data)) {
          if (key.includes("github.com") && (value as any).oauth_token) {
            return { hasToken: true, token: (value as any).oauth_token };
          }
        }
      }
    } catch {
      // Continue to next file
    }
  }

  return {
    hasToken: false,
    error:
      "No Copilot token found. Install GitHub Copilot extension in your editor first.",
  };
}

// ============================================================================
// API Fetch
// ============================================================================

async function fetchUsage(token: string): Promise<UsageData | null> {
  try {
    const response = await fetch(
      "https://api.github.com/copilot_internal/user",
      {
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: "application/json",
          "User-Agent": "pi-copilot-usage",
        },
      },
    );

    if (!response.ok) {
      return null;
    }

    const data = (await response.json()) as CopilotUserResponse;

    // Check for premium interactions quota
    const premium = data.quota_snapshots?.premium_interactions;
    if (premium) {
      return {
        used: premium.entitlement - premium.remaining,
        quota: premium.entitlement,
        remaining: premium.remaining,
        resetDate: data.quota_reset_date,
        unlimited: premium.unlimited,
        overagePermitted: premium.overage_permitted,
        plan: data.copilot_plan,
      };
    }

    // For limited/free users
    if (
      data.access_type_sku === "free_limited_copilot" &&
      data.limited_user_quotas
    ) {
      // Free tier doesn't have premium_interactions, use chat quota as proxy
      const chatQuota = data.monthly_quotas?.chat || 50;
      const chatRemaining = data.limited_user_quotas.chat || 0;
      return {
        used: chatQuota - chatRemaining,
        quota: chatQuota,
        remaining: chatRemaining,
        resetDate: data.limited_user_reset_date || data.quota_reset_date,
        unlimited: false,
        overagePermitted: false,
        plan: "free",
      };
    }

    return null;
  } catch {
    return null;
  }
}

// ============================================================================
// Date Calculations
// ============================================================================

function getDaysRemaining(resetDateStr: string): number {
  if (!resetDateStr) return 0;

  const now = new Date();
  // Reset date is in YYYY-MM-DD format
  const parts = resetDateStr.split("-").map(Number);
  if (parts.length !== 3 || parts.some(isNaN)) return 0;

  const [year, month, day] = parts;
  const resetDate = new Date(year, month - 1, day); // month is 0-indexed in Date
  const diffMs = resetDate.getTime() - now.getTime();
  return Math.max(0, Math.ceil(diffMs / (1000 * 60 * 60 * 24)));
}

function getDaysInCurrentPeriod(): number {
  // Approximate as 30 days for the billing period
  return 30;
}

// ============================================================================
// Progress Bar Rendering
// ============================================================================

function renderProgressBar(
  current: number,
  max: number,
  width: number,
  theme: ExtensionContext["ui"]["theme"],
  colorize: boolean,
): string {
  const ratio = max > 0 ? Math.max(0, Math.min(current / max, 1)) : 0;
  const filled = Math.round(ratio * width);
  const empty = width - filled;

  const filledChar = "█";
  const emptyChar = "░";

  const bar = filledChar.repeat(filled) + emptyChar.repeat(empty);

  if (!colorize) return bar;

  // Color based on usage percentage
  const percent = ratio * 100;
  if (percent >= 90) {
    return theme.fg("error", bar);
  } else if (percent >= 70) {
    return theme.fg("warning", bar);
  }
  return theme.fg("success", bar);
}

// ============================================================================
// Widget Display
// ============================================================================

function updateWidget(
  ctx: ExtensionContext,
  usageData: UsageData | null,
  authStatus: AuthStatus,
): void {
  const theme = ctx.ui.theme;

  // Handle error states
  if (!authStatus.hasToken) {
    ctx.ui.setWidget(
      WIDGET_ID,
      [
        theme.fg("error", " Copilot: ") +
          theme.fg("dim", authStatus.error || "No token"),
      ],
      WIDGET_PLACEMENT,
    );
    return;
  }

  if (!usageData) {
    ctx.ui.setWidget(
      WIDGET_ID,
      [
        theme.fg("warning", " Copilot: ") +
          theme.fg("dim", "Failed to fetch usage data"),
      ],
      WIDGET_PLACEMENT,
    );
    return;
  }

  // Handle unlimited users
  if (usageData.unlimited) {
    ctx.ui.setWidget(
      WIDGET_ID,
      [
        theme.fg("success", "  Copilot: ") +
          theme.fg("dim", "Unlimited premium requests"),
      ],
      WIDGET_PLACEMENT,
    );
    return;
  }

  const { used, quota, resetDate } = usageData;

  // Usage progress bar
  const percent = quota > 0 ? ((used / quota) * 100).toFixed(1) : "0.0";
  const usageBar = renderProgressBar(used, quota, BAR_WIDTH, theme, true);
  const usagePart = `${usageBar} ${used}/${quota} (${percent}%)`;

  // Days remaining with reset date
  const daysRemaining = getDaysRemaining(resetDate);
  const totalDays = getDaysInCurrentPeriod();
  const daysPassed = Math.max(0, totalDays - daysRemaining);
  const daysBar = renderProgressBar(
    daysPassed,
    totalDays,
    BAR_WIDTH,
    theme,
    false,
  );
  const daysPart = `${daysBar} ${daysRemaining}d left ( ${resetDate})`;

  const combinedLine = ` ${usagePart} ${daysPart}`;
  ctx.ui.setWidget(WIDGET_ID, [combinedLine], WIDGET_PLACEMENT);
}

// ============================================================================
// Main Extension
// ============================================================================

export default function copilotUsageExtension(pi: ExtensionAPI) {
  let cachedUsage: UsageData | null = null;
  let cachedAuth: AuthStatus | null = null;

  // Load initial visibility from settings (defaults to true if not set)
  const settings = loadSettings();
  let widgetVisible = settings.copilotUsageVisible !== false;

  async function refresh(ctx: ExtensionContext): Promise<void> {
    if (!ctx.hasUI) return;

    if (!widgetVisible) {
      ctx.ui.setWidget(WIDGET_ID, [], WIDGET_PLACEMENT);
      return;
    }

    cachedAuth = getOAuthToken();

    if (cachedAuth.hasToken && cachedAuth.token) {
      cachedUsage = await fetchUsage(cachedAuth.token);
    } else {
      cachedUsage = null; // Clear stale data on auth failure
    }

    updateWidget(ctx, cachedUsage, cachedAuth);
  }

  // Initial load on session start
  pi.on("session_start", async (_event, ctx) => {
    await refresh(ctx);
  });

  // Refresh on session switch
  pi.on("session_switch", async (_event, ctx) => {
    await refresh(ctx);
  });

  // Manual refresh command
  pi.registerCommand("copilot-usage", {
    description: "Refresh GitHub Copilot premium request usage",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;

      ctx.ui.notify("Refreshing Copilot usage...", "info");
      await refresh(ctx);

      if (cachedUsage) {
        if (cachedUsage.unlimited) {
          ctx.ui.notify("Unlimited premium requests", "success");
        } else {
          ctx.ui.notify(
            `${cachedUsage.used}/${cachedUsage.quota} requests used (${cachedUsage.remaining} remaining)`,
            "success",
          );
        }
      } else if (cachedAuth?.error) {
        ctx.ui.notify(cachedAuth.error, "error");
      } else {
        ctx.ui.notify("Failed to fetch usage data", "error");
      }
    },
  });

  // Toggle widget visibility
  pi.registerCommand("copilot-usage-toggle", {
    description: "Toggle GitHub Copilot usage widget visibility",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;

      widgetVisible = !widgetVisible;
      await refresh(ctx);
      ctx.ui.notify(
        `Copilot usage widget ${widgetVisible ? "shown" : "hidden"}`,
        "info",
      );
    },
  });
}
