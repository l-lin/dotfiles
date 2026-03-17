// ============================================================================
// GitHub Copilot Extension — API Calls
// ============================================================================

import type {
  CopilotModel,
  CopilotTokenResponse,
  UsageData,
  CopilotUserResponse,
} from "./types.js";

const COMMON_HEADERS = {
  Accept: "application/json",
  "User-Agent": "pi-copilot-usage",
} as const;

const COPILOT_HEADERS = {
  "X-Github-Api-Version": "2025-10-01",
  "Editor-Version": "pi/1.0",
  "Copilot-Integration-Id": "vscode-chat",
} as const;

function parsePremiumUsage(data: CopilotUserResponse): UsageData | null {
  const premium = data.quota_snapshots?.premium_interactions;
  if (!premium) return null;

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

function parseFreeUsage(data: CopilotUserResponse): UsageData | null {
  if (
    data.access_type_sku !== "free_limited_copilot" ||
    !data.limited_user_quotas
  ) {
    return null;
  }

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

export async function fetchUsage(
  oauthToken: string,
): Promise<UsageData | null> {
  try {
    const response = await fetch(
      "https://api.github.com/copilot_internal/user",
      {
        headers: {
          Authorization: `Bearer ${oauthToken}`,
          ...COMMON_HEADERS,
        },
      },
    );
    if (!response.ok) return null;

    const data = (await response.json()) as CopilotUserResponse;
    return parsePremiumUsage(data) ?? parseFreeUsage(data);
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
          ...COMMON_HEADERS,
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

function sortModels(models: CopilotModel[]): CopilotModel[] {
  return models.sort((a, b) => {
    const multiplierA = a.multiplier ?? 999;
    const multiplierB = b.multiplier ?? 999;
    if (multiplierA !== multiplierB) {
      return multiplierA - multiplierB;
    }
    return a.name.localeCompare(b.name);
  });
}

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
        ...COPILOT_HEADERS,
        ...COMMON_HEADERS,
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
      }));

    cachedModels = sortModels(models);
    return cachedModels;
  } catch {
    return [];
  }
}
