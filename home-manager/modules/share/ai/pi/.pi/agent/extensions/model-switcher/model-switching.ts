import type { KeyId } from "@mariozechner/pi-tui";

const DEFAULT_KEYBIND = "alt-m";
const MODIFIERS = new Set(["ctrl", "shift", "alt"]);

export type ConfiguredThinkingLevel =
  | "minimal"
  | "low"
  | "medium"
  | "high"
  | "xhigh";

export interface ConfiguredModel {
  reference: string;
  thinkingLevel?: ConfiguredThinkingLevel;
}

export const CONFIGURED_MODELS: ConfiguredModel[] = [
  { reference: "github-copilot/gpt-4.1" },
  { reference: "github-copilot/gpt-5.4", thinkingLevel: "xhigh" },
  { reference: "ollama/gemma4:26b", thinkingLevel: "high" },
];

export interface ModelReferenceLike {
  provider: string;
  id: string;
}

interface ParsedModelReference {
  provider: string;
  modelId: string;
}

export interface ModelRegistryLookup<TModel> {
  find(provider: string, modelId: string): TModel | undefined;
}

export function normalizeKeybind(keybind: string | undefined): KeyId {
  const trimmed = keybind?.trim().toLowerCase() || DEFAULT_KEYBIND;

  if (trimmed.includes("+")) return trimmed as KeyId;

  const parts = trimmed.split("-").filter((part) => part.length > 0);
  const hasModifierPrefix =
    parts.length > 1 && parts.slice(0, -1).every((part) => MODIFIERS.has(part));

  if (hasModifierPrefix) {
    const modifierPrefix = parts.slice(0, -1).join("+");
    const key = parts.at(-1)!;
    return `${modifierPrefix}+${key}` as KeyId;
  }

  return trimmed as KeyId;
}

export function formatModelReference(
  model: ModelReferenceLike | undefined,
): string | undefined {
  if (!model) return undefined;
  return `${model.provider}/${model.id}`;
}

function parseModelReference(
  reference: string,
): ParsedModelReference | undefined {
  const trimmedReference = reference.trim();
  const separatorIndex = trimmedReference.indexOf("/");

  if (separatorIndex <= 0 || separatorIndex >= trimmedReference.length - 1) {
    return undefined;
  }

  return {
    provider: trimmedReference.slice(0, separatorIndex),
    modelId: trimmedReference.slice(separatorIndex + 1),
  };
}

function rotateList<T>(items: T[], currentIndex: number): T[] {
  if (items.length <= 1) return [...items];

  const nextIndex = currentIndex >= 0 ? (currentIndex + 1) % items.length : 1;

  return [...items.slice(nextIndex), ...items.slice(0, nextIndex)];
}

export function rotateModels(
  models: string[],
  currentModelReference: string | undefined,
): string[] {
  const configuredModels = models.filter(
    (model) => typeof model === "string" && model.trim().length > 0,
  );
  const currentIndex = currentModelReference
    ? configuredModels.indexOf(currentModelReference)
    : -1;

  return rotateList(configuredModels, currentIndex);
}

export function rotateConfiguredModels(
  models: ConfiguredModel[],
  currentModelReference: string | undefined,
): ConfiguredModel[] {
  const configuredModels = models.filter(
    (model) =>
      typeof model.reference === "string" && model.reference.trim().length > 0,
  );
  const currentIndex = currentModelReference
    ? configuredModels.findIndex(
        (model) => model.reference === currentModelReference,
      )
    : -1;

  return rotateList(configuredModels, currentIndex);
}

export function resolveConfiguredModel<TModel>(
  modelRegistry: ModelRegistryLookup<TModel>,
  reference: string,
): TModel {
  const parsedReference = parseModelReference(reference);

  if (!parsedReference) {
    throw new Error(
      `Invalid model reference \"${reference}\". Use provider/model.`,
    );
  }

  const model = modelRegistry.find(
    parsedReference.provider,
    parsedReference.modelId,
  );

  if (!model) {
    throw new Error(`Configured model \"${reference}\" is not available.`);
  }

  return model;
}
