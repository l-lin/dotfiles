export interface SnippetTabstop {
  index: number;
  start: number;
  end: number;
}

export interface ParsedSnippetExpansion {
  kind: "parsed";
  text: string;
  tabstops: SnippetTabstop[];
  finalStop: number;
  hasExplicitFinalStop: boolean;
}

export interface LiteralSnippetExpansion {
  kind: "literal";
  text: string;
}

export type SnippetExpansion = ParsedSnippetExpansion | LiteralSnippetExpansion;
export type PlaceholderRenderStyle = "plain" | "bracketed";

function isUnsupportedBareTabstop(text: string, offset: number): boolean {
  return /\$[1-9](?!\d)/.test(text.slice(offset));
}

function hasNestedPlaceholderSyntax(text: string): boolean {
  return (
    text.includes("${") || text.includes("$0") || /\$[1-9](?!\d)/.test(text)
  );
}

function fallbackLiteral(text: string): LiteralSnippetExpansion {
  return { kind: "literal", text };
}

export function parseSnippetExpansion(expansion: string): SnippetExpansion {
  const textParts: string[] = [];
  const tabstops: SnippetTabstop[] = [];
  const seenIndices = new Set<number>();
  let hasExplicitFinalStop = false;
  let finalStop = 0;

  for (let cursor = 0; cursor < expansion.length; ) {
    if (expansion.startsWith("$0", cursor)) {
      if (hasExplicitFinalStop) {
        return fallbackLiteral(expansion);
      }

      hasExplicitFinalStop = true;
      finalStop = textParts.join("").length;
      cursor += 2;
      continue;
    }

    if (expansion.startsWith("${", cursor)) {
      const closingBrace = expansion.indexOf("}", cursor + 2);
      if (closingBrace === -1) {
        return fallbackLiteral(expansion);
      }

      const body = expansion.slice(cursor + 2, closingBrace);
      const separatorIndex = body.indexOf(":");
      const indexText =
        separatorIndex === -1 ? body : body.slice(0, separatorIndex);
      const defaultText =
        separatorIndex === -1 ? "" : body.slice(separatorIndex + 1);

      if (
        !/^[1-9][0-9]*$/.test(indexText) ||
        hasNestedPlaceholderSyntax(defaultText)
      ) {
        return fallbackLiteral(expansion);
      }

      const index = Number(indexText);
      if (seenIndices.has(index)) {
        return fallbackLiteral(expansion);
      }

      seenIndices.add(index);

      const start = textParts.join("").length;
      textParts.push(defaultText);
      const end = textParts.join("").length;
      tabstops.push({ index, start, end });
      cursor = closingBrace + 1;
      continue;
    }

    if (isUnsupportedBareTabstop(expansion, cursor)) {
      return fallbackLiteral(expansion);
    }

    textParts.push(expansion[cursor] ?? "");
    cursor += 1;
  }

  const text = textParts.join("");
  if (!hasExplicitFinalStop) {
    finalStop = text.length;
  }

  return {
    kind: "parsed",
    text,
    tabstops: [...tabstops].sort((left, right) => left.index - right.index),
    finalStop,
    hasExplicitFinalStop,
  };
}

function cloneParsedSnippetExpansion(
  expansion: ParsedSnippetExpansion,
): ParsedSnippetExpansion {
  return {
    kind: "parsed",
    text: expansion.text,
    tabstops: expansion.tabstops.map((tabstop) => ({ ...tabstop })),
    finalStop: expansion.finalStop,
    hasExplicitFinalStop: expansion.hasExplicitFinalStop,
  };
}

export function formatParsedSnippetExpansion(
  expansion: ParsedSnippetExpansion,
  style: PlaceholderRenderStyle,
): ParsedSnippetExpansion {
  if (style === "plain" || expansion.tabstops.length === 0) {
    return cloneParsedSnippetExpansion(expansion);
  }

  const tabstopsByStart = [...expansion.tabstops].sort(
    (left, right) => left.start - right.start,
  );
  const updatedTabstopsByIndex = new Map<number, SnippetTabstop>();
  const textParts: string[] = [];
  let nextSliceStart = 0;
  let renderedLength = 0;
  let finalStop = expansion.finalStop;

  for (const tabstop of tabstopsByStart) {
    const prefix = expansion.text.slice(nextSliceStart, tabstop.start);
    textParts.push(prefix);
    renderedLength += prefix.length;

    const placeholderText = expansion.text.slice(tabstop.start, tabstop.end);
    const bracketedText = `[${placeholderText}]`;
    const start = renderedLength;
    textParts.push(bracketedText);
    renderedLength += bracketedText.length;
    updatedTabstopsByIndex.set(tabstop.index, {
      index: tabstop.index,
      start,
      end: renderedLength,
    });

    if (tabstop.end <= expansion.finalStop) {
      finalStop += 2;
    }

    nextSliceStart = tabstop.end;
  }

  textParts.push(expansion.text.slice(nextSliceStart));

  return {
    kind: "parsed",
    text: textParts.join(""),
    tabstops: expansion.tabstops.map((tabstop) => {
      const updatedTabstop = updatedTabstopsByIndex.get(tabstop.index);
      if (!updatedTabstop) {
        throw new Error(`Missing formatted tabstop for index ${tabstop.index}`);
      }

      return updatedTabstop;
    }),
    finalStop,
    hasExplicitFinalStop: expansion.hasExplicitFinalStop,
  };
}

export function renderSnippetExpansion(
  expansion: string,
  style: PlaceholderRenderStyle = "plain",
): string {
  const parsedExpansion = parseSnippetExpansion(expansion);

  return parsedExpansion.kind === "parsed"
    ? formatParsedSnippetExpansion(parsedExpansion, style).text
    : parsedExpansion.text;
}
