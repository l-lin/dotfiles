import os from "node:os";

export function normalizePlatformLineEndings(text: string): string {
  const normalized = text.replace(/\r\n?|\n/g, "\n");
  return os.EOL === "\n" ? normalized : normalized.replaceAll("\n", os.EOL);
}

export function toInternalLineEndings(text: string): string {
  return text.replace(/\r\n?|\n/g, "\n");
}

export function fromAssistantContent(content: unknown): string | null {
  if (!Array.isArray(content)) return null;

  let hasText = false;
  const parts: string[] = [];

  for (const block of content) {
    if (!isRecord(block) || typeof block.type !== "string") continue;
    if (isThinkingBlock(block.type)) continue;

    if (block.type === "text" && typeof block.text === "string") {
      hasText ||= block.text.trim().length > 0;
      parts.push(block.text);
      continue;
    }

    parts.push(`[${formatBlockType(block.type)}]`);
  }

  if (!hasText) return null;

  return normalizePlatformLineEndings(parts.join("\n"));
}

function formatBlockType(type: string): string {
  return type
    .replace(/([a-z])([A-Z])/g, "$1 $2")
    .replace(/[-_]+/g, " ")
    .toLowerCase();
}

function isThinkingBlock(type: string): boolean {
  const normalizedType = formatBlockType(type).replaceAll(" ", "");
  return normalizedType === "thinking" || normalizedType === "redactedthinking";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
