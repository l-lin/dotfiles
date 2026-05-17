import * as fs from "node:fs";
import * as path from "node:path";
import {
  isSymbolInformation,
  symbolKindToLabel,
  type LspDocumentSymbol,
  type LspLocation,
  type LspRange,
  type LspSymbolInformation,
  type LspWorkspaceSymbol,
} from "./protocol.js";
import { fileUriToPath } from "./resolver.js";

const DEFAULT_MAX_RESULTS = 20;
const PREVIEW_WHITESPACE = /\s+/g;

export function formatLocationResult(
  locations: LspLocation[],
  cwd: string,
  options: { title: string; maxResults?: number },
): string {
  const maxResults = options.maxResults ?? DEFAULT_MAX_RESULTS;
  const visibleLocations = locations.slice(0, maxResults);
  const lines = [`${options.title} (${locations.length} result(s))`];

  for (const location of visibleLocations) {
    lines.push(`- ${formatLocationLine(location, cwd)}`);
  }

  appendOverflowLine(lines, locations.length, visibleLocations.length);
  return lines.join("\n");
}

export function formatWorkspaceSymbolResult(
  symbols: LspWorkspaceSymbol[],
  cwd: string,
  maxResults: number = DEFAULT_MAX_RESULTS,
): string {
  const visibleSymbols = symbols.slice(0, maxResults);
  const lines = [`Workspace symbols (${symbols.length} result(s))`];

  for (const symbol of visibleSymbols) {
    const kind = symbolKindToLabel(symbol.kind);
    const container = symbol.containerName ? ` — ${symbol.containerName}` : "";
    const location = symbol.location
      ? formatLocationLabel(symbol.location, cwd)
      : "(location unavailable)";
    lines.push(`- ${symbol.name} [${kind}]${container} @ ${location}`);
  }

  appendOverflowLine(lines, symbols.length, visibleSymbols.length);
  return lines.join("\n");
}

export function formatDocumentSymbolResult(
  filePath: string,
  symbols: Array<LspDocumentSymbol | LspSymbolInformation>,
): string {
  const lines = [`Document symbols for ${filePath}`];

  if (symbols.length === 0) {
    lines.push("(no symbols)");
    return lines.join("\n");
  }

  if (symbols.every(isSymbolInformation)) {
    for (const symbol of symbols) {
      lines.push(`- ${formatSymbolInformation(symbol)}`);
    }
    return lines.join("\n");
  }

  for (const symbol of symbols) {
    if (isSymbolInformation(symbol)) {
      lines.push(`- ${formatSymbolInformation(symbol)}`);
      continue;
    }

    pushDocumentSymbolLines(lines, symbol, 0);
  }

  return lines.join("\n");
}

function pushDocumentSymbolLines(
  lines: string[],
  symbol: LspDocumentSymbol,
  depth: number,
): void {
  const indent = "  ".repeat(depth);
  lines.push(
    `${indent}- ${symbol.name} [${symbolKindToLabel(symbol.kind)}] @ ${formatRangeLabel(symbol.range)}`,
  );

  for (const child of symbol.children ?? []) {
    pushDocumentSymbolLines(lines, child, depth + 1);
  }
}

function formatSymbolInformation(symbol: LspSymbolInformation): string {
  const container = symbol.containerName ? ` — ${symbol.containerName}` : "";
  return `${symbol.name} [${symbolKindToLabel(symbol.kind)}]${container} @ ${formatRangeLabel(symbol.location.range)}`;
}

function appendOverflowLine(
  lines: string[],
  totalCount: number,
  visibleCount: number,
): void {
  const remainingCount = totalCount - visibleCount;
  if (remainingCount > 0) {
    lines.push(`... ${remainingCount} more result(s) not shown`);
  }
}

function formatLocationLine(location: LspLocation, cwd: string): string {
  const locationLabel = formatLocationLabel(location, cwd);
  const filePath = fileUriToPath(location.uri);
  const preview = readLinePreview(filePath, location.range.start.line + 1);
  return `${locationLabel} | ${preview}`;
}

function formatLocationLabel(location: LspLocation, cwd: string): string {
  const filePath = fileUriToPath(location.uri);
  const relativePath = path.relative(cwd, filePath) || path.basename(filePath);
  const line = location.range.start.line + 1;
  const character = location.range.start.character + 1;
  return `${relativePath}:${line}:${character}`;
}

function readLinePreview(filePath: string, oneBasedLine: number): string {
  try {
    const lines = fs.readFileSync(filePath, "utf8").split(/\r?\n/);
    const preview = lines[oneBasedLine - 1] ?? "";
    return preview.trim().replace(PREVIEW_WHITESPACE, " ");
  } catch {
    return "(source unavailable)";
  }
}

function formatRangeLabel(range: LspRange): string {
  return `${range.start.line + 1}:${range.start.character + 1}-${range.end.line + 1}:${range.end.character + 1}`;
}
