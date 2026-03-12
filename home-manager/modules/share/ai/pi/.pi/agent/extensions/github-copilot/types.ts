// ============================================================================
// GitHub Copilot Extension — Type Definitions
// ============================================================================

export interface CopilotUserResponse {
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
    chat?: { entitlement: number; remaining: number; unlimited: boolean };
    completions?: {
      entitlement: number;
      remaining: number;
      unlimited: boolean;
    };
  };
  limited_user_quotas?: { chat: number; completions: number };
  limited_user_reset_date?: string;
  monthly_quotas?: { chat: number; completions: number };
}

export interface UsageData {
  used: number;
  quota: number;
  remaining: number;
  resetDate: string;
  unlimited: boolean;
  overagePermitted: boolean;
  plan: string;
}

export interface AuthStatus {
  hasToken: boolean;
  token?: string;
  error?: string;
}

export interface CopilotModel {
  id: string;
  name: string;
  multiplier: number | null;
  isPremium: boolean;
}

export interface CopilotTokenResponse {
  token: string;
  endpoints?: { api?: string };
}

export interface CopilotUsageSettings {
  visible?: boolean;
}

export interface PiSettings {
  extensionSettings?: {
    copilotUsage?: CopilotUsageSettings;
  };
}
