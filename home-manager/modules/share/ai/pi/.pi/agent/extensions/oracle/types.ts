import type { Model, Api } from "@mariozechner/pi-ai";

export const ORACLE_MODELS = [
  { provider: "github-copilot", model: "gpt-4o", name: "GPT-4o" },
  { provider: "github-copilot", model: "gpt-4.1", name: "GPT-4.1" },
  { provider: "github-copilot", model: "gpt-5-mini", name: "GPT-5 Mini" },
  { provider: "openai", model: "gpt-4.1-mini", name: "GPT-4.1 Mini" },
  { provider: "openai", model: "gpt-4.1-nano", name: "GPT-4.1 Nano" },
  { provider: "openai", model: "o1", name: "o1" },
  { provider: "openai", model: "o1-mini", name: "o1-mini" },
  { provider: "openai", model: "o1-pro", name: "o1-pro" },
  { provider: "openai", model: "o3-mini", name: "o3-mini" },
  {
    provider: "anthropic",
    model: "claude-haiku-3-5",
    name: "Claude Haiku 3.5",
  },
  {
    provider: "anthropic",
    model: "claude-sonnet-4-5",
    name: "Claude Sonnet 4.5",
  },
  { provider: "anthropic", model: "claude-opus-4-5", name: "Claude Opus 4.5" },
  { provider: "anthropic", model: "claude-opus-4-6", name: "Claude Opus 4.6" },
] as const;

export interface AvailableModel {
  provider: string;
  modelId: string;
  name: string;
  model: Model<Api>;
  apiKey?: string;
  headers?: Record<string, string>;
}
