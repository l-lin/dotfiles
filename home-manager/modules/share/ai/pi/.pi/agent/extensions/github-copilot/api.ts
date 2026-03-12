// ============================================================================
// GitHub Copilot Extension — API Calls
// ============================================================================

import type {
  CopilotModel,
  CopilotTokenResponse,
  UsageData,
  CopilotUserResponse,
} from "./types.js";

export async function fetchUsage(
  oauthToken: string,
): Promise<UsageData | null> {
  try {
    const response = await fetch(
      "https://api.github.com/copilot_internal/user",
      {
        headers: {
          Authorization: `Bearer ${oauthToken}`,
          Accept: "application/json",
          "User-Agent": "pi-copilot-usage",
        },
      },
    );
    if (!response.ok) return null;

    const data = (await response.json()) as CopilotUserResponse;
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

    // Free/limited tier fallback
    if (
      data.access_type_sku === "free_limited_copilot" &&
      data.limited_user_quotas
    ) {
      const chatQuota = data.monthly_quotas?.chat ?? 50;
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

async function fetchCopilotToken(
  oauthToken: string,
): Promise<CopilotTokenResponse | null> {
  try {
    const response = await fetch(
      "https://api.github.com/copilot_internal/v2/token",
      {
        headers: {
          Authorization: `Bearer ${oauthToken}`,
          Accept: "application/json",
          "User-Agent": "pi-copilot-usage",
        },
      },
    );
    if (!response.ok) return null;
    return (await response.json()) as CopilotTokenResponse;
  } catch {
    return null;
  }
}

let cachedModels: CopilotModel[] | null = null;

export async function fetchCopilotModels(
  oauthToken: string,
): Promise<CopilotModel[]> {
  if (cachedModels) return cachedModels;

  const tokenData = await fetchCopilotToken(oauthToken);
  if (!tokenData?.token) return [];

  const baseUrl = tokenData.endpoints?.api ?? "https://api.githubcopilot.com";
  try {
    const response = await fetch(`${baseUrl}/models`, {
      headers: {
        Authorization: `Bearer ${tokenData.token}`,
        "X-Github-Api-Version": "2025-10-01",
        // These two headers are required — without them the API returns:
        // "bad request: missing Editor-Version header for IDE auth"
        "Editor-Version": "pi/1.0",
        "Copilot-Integration-Id": "vscode-chat",
        Accept: "application/json",
        "User-Agent": "pi-copilot-usage",
      },
    });
    if (!response.ok) return [];

    const json = (await response.json()) as { data: any[] };
    if (!Array.isArray(json.data)) return [];

    const models = json.data
      .filter((m) => m.model_picker_enabled)
      .map((m) => ({
        id: m.id as string,
        name: (m.name ?? m.id) as string,
        multiplier: (m.billing?.multiplier ?? null) as number | null,
        isPremium: (m.billing?.is_premium ?? false) as boolean,
      }))
      .sort((a, b) => {
        // Free models first, then by multiplier ascending, then alphabetically
        const ma = a.multiplier ?? 999;
        const mb = b.multiplier ?? 999;
        return ma !== mb ? ma - mb : a.name.localeCompare(b.name);
      });

    cachedModels = models;
    return models;
  } catch {
    return [];
  }
}
