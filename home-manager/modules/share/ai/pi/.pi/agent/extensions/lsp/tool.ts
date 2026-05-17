import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type, type Static } from "typebox";
import { collectDiagnostics } from "./collector.js";
import {
  getOrCreateLspClient,
  handleLspClientError,
} from "./client-registry.js";
import { LSP_SERVERS_CONFIG } from "./lsp-servers.js";
import { normalizeLocationResult, toLspPosition } from "./protocol.js";
import { resolveTargetContext, resolveFileCommands } from "./targets.js";
import type { LspClientEntry, SavedConfig } from "./types.js";
import { formatDiagnostics } from "./ui/format.js";
import { setLspWidget, syncLspServers } from "./ui/widget.js";
import {
  formatDocumentSymbolResult,
  formatLocationResult,
  formatWorkspaceSymbolResult,
} from "./navigation-format.js";
import { applyWorkspaceEdit } from "./workspace-edit.js";

const DEFAULT_MAX_RESULTS = 20;
const OPERATION_TIMEOUT_MS = 5_000;
const LSP_OPERATION_SCHEMA = Type.Union(
  [
    Type.Literal("diagnostics"),
    Type.Literal("workspace_symbols"),
    Type.Literal("document_symbols"),
    Type.Literal("definition"),
    Type.Literal("references"),
    Type.Literal("rename"),
  ],
  {
    description:
      "Which LSP feature to run: diagnostics, workspace_symbols, document_symbols, definition, references, or rename.",
  },
);

export const LspToolParams = Type.Object({
  operation: LSP_OPERATION_SCHEMA,
  path: Type.Optional(
    Type.String({
      description:
        "File or directory path, relative to cwd. Defaults to cwd for diagnostics and workspace_symbols.",
    }),
  ),
  query: Type.Optional(
    Type.String({
      description:
        "Workspace symbol query. Required for workspace_symbols. Use a class, method, or function name fragment.",
    }),
  ),
  line: Type.Optional(
    Type.Integer({
      minimum: 1,
      description:
        "1-based line number for definition, references, and rename.",
    }),
  ),
  character: Type.Optional(
    Type.Integer({
      minimum: 1,
      description:
        "1-based character number for definition, references, and rename.",
    }),
  ),
  includeDeclaration: Type.Optional(
    Type.Boolean({
      description:
        "Whether references should include the declaration location. Defaults to false.",
    }),
  ),
  newName: Type.Optional(
    Type.String({
      description: "New symbol name for rename.",
      minLength: 1,
    }),
  ),
  maxResults: Type.Optional(
    Type.Integer({
      minimum: 1,
      maximum: 200,
      description:
        "Maximum number of locations or symbols to include in the result. Defaults to 20.",
    }),
  ),
});

export type LspToolInput = Static<typeof LspToolParams>;

type ToolResult = {
  content: Array<{ type: "text"; text: string }>;
  details: Record<string, unknown>;
};

type CandidateRequestResult<T> = {
  result: T | null;
  errors: string[];
};

export async function executeLspTool(
  input: LspToolInput,
  signal: AbortSignal | undefined,
  ctx: ExtensionContext,
  lspClients: Map<string, LspClientEntry>,
  savedConfig: SavedConfig | null,
): Promise<ToolResult> {
  switch (input.operation) {
    case "diagnostics":
      return runDiagnostics(input, ctx, lspClients, savedConfig);
    case "workspace_symbols":
      return runWorkspaceSymbols(input, signal, ctx, lspClients, savedConfig);
    case "document_symbols":
      return runDocumentSymbols(input, signal, ctx, lspClients, savedConfig);
    case "definition":
      return runDefinition(input, signal, ctx, lspClients, savedConfig);
    case "references":
      return runReferences(input, signal, ctx, lspClients, savedConfig);
    case "rename":
      return runRename(input, signal, ctx, lspClients, savedConfig);
    default:
      return errorResult(`Unsupported LSP operation: ${input.operation}`);
  }
}

async function runDiagnostics(
  input: LspToolInput,
  ctx: ExtensionContext,
  lspClients: Map<string, LspClientEntry>,
  savedConfig: SavedConfig | null,
): Promise<ToolResult> {
  const resolvedTarget = resolveTargetContext(
    input.path,
    ctx.cwd,
    savedConfig,
    LSP_SERVERS_CONFIG,
  );

  if (!fs.existsSync(resolvedTarget.targetPath)) {
    return errorResult(`Path not found: ${input.path ?? "."}`);
  }

  if (resolvedTarget.files.length === 0) {
    return errorResult(
      `No supported files found under ${displayPath(resolvedTarget.targetPath, ctx.cwd)}.`,
    );
  }

  if (resolvedTarget.commands.length === 0) {
    return errorResult("No LSP servers are configured for that target.");
  }

  const { merged, servers } = await collectDiagnostics(
    resolvedTarget.files,
    resolvedTarget.commands,
    lspClients,
    ctx,
  );

  if (servers.length === 0) {
    return errorResult("No LSP servers were available for diagnostics.");
  }

  const { text, errorCount, warningCount, infoCount, hintCount } =
    formatDiagnostics(merged, ctx.cwd);
  const totalIssues = errorCount + warningCount + infoCount + hintCount;
  const targetLabel = displayPath(resolvedTarget.targetPath, ctx.cwd);

  if (totalIssues === 0) {
    return successResult(`No LSP diagnostics issues found in ${targetLabel}.`, {
      operation: "diagnostics",
      targetPath: resolvedTarget.targetPath,
      fileCount: resolvedTarget.files.length,
      serverCount: servers.length,
    });
  }

  const summary = `${errorCount} error(s), ${warningCount} warning(s), ${infoCount} info(s), ${hintCount} hint(s)`;
  return successResult(
    `LSP diagnostics for ${targetLabel} (${summary})\n${text}`,
    {
      operation: "diagnostics",
      targetPath: resolvedTarget.targetPath,
      fileCount: resolvedTarget.files.length,
      serverCount: servers.length,
      errorCount,
      warningCount,
      infoCount,
      hintCount,
    },
  );
}

async function runWorkspaceSymbols(
  input: LspToolInput,
  signal: AbortSignal | undefined,
  ctx: ExtensionContext,
  lspClients: Map<string, LspClientEntry>,
  savedConfig: SavedConfig | null,
): Promise<ToolResult> {
  const query = input.query?.trim();
  if (!query) {
    return errorResult("workspace_symbols requires a non-empty query.");
  }

  const resolvedTarget = resolveTargetContext(
    input.path,
    ctx.cwd,
    savedConfig,
    LSP_SERVERS_CONFIG,
  );

  if (!fs.existsSync(resolvedTarget.targetPath)) {
    return errorResult(`Path not found: ${input.path ?? "."}`);
  }

  if (resolvedTarget.commands.length === 0) {
    return errorResult("No LSP servers are configured for that target.");
  }

  syncLspServers(
    ctx,
    resolvedTarget.commands.map(({ resolved }) =>
      path.basename(resolved.command[0]!),
    ),
  );

  const symbols = [] as Awaited<
    ReturnType<LspClientEntry["client"]["getWorkspaceSymbols"]>
  >;
  const errors: string[] = [];

  for (const command of resolvedTarget.commands) {
    let commandKey = "";
    try {
      const activeClient = await getOrCreateLspClient(
        command.resolved,
        command.rootSourcePath,
        ctx,
        lspClients,
      );
      commandKey = activeClient.commandKey;
      setLspWidget(ctx, activeClient.entry.bin, "collecting");
      const result = await activeClient.entry.client.getWorkspaceSymbols(
        query,
        OPERATION_TIMEOUT_MS,
        signal,
      );
      setLspWidget(ctx, activeClient.entry.bin, "idle");
      symbols.push(...result);
    } catch (err) {
      errors.push(err instanceof Error ? err.message : String(err));
      handleLspClientError(err, commandKey, ctx, lspClients);
    }
  }

  if (symbols.length === 0 && errors.length > 0) {
    return errorResult(`Workspace symbol search failed: ${errors.join(" | ")}`);
  }

  if (symbols.length === 0) {
    return successResult(
      `No workspace symbols matched ${JSON.stringify(query)}.`,
      {
        operation: "workspace_symbols",
        query,
        resultCount: 0,
      },
    );
  }

  const maxResults = input.maxResults ?? DEFAULT_MAX_RESULTS;
  const deduplicatedSymbols = dedupeWorkspaceSymbols(symbols);
  return successResult(
    formatWorkspaceSymbolResult(deduplicatedSymbols, ctx.cwd, maxResults),
    {
      operation: "workspace_symbols",
      query,
      resultCount: deduplicatedSymbols.length,
      serverCount: resolvedTarget.commands.length,
    },
  );
}

async function runDocumentSymbols(
  input: LspToolInput,
  signal: AbortSignal | undefined,
  ctx: ExtensionContext,
  lspClients: Map<string, LspClientEntry>,
  savedConfig: SavedConfig | null,
): Promise<ToolResult> {
  const targetFilePath = requireExistingFilePath(
    input.path,
    ctx.cwd,
    "document_symbols",
  );
  if (targetFilePath instanceof Error) {
    return errorResult(targetFilePath.message);
  }

  const commands = resolveFileCommands(
    targetFilePath,
    savedConfig,
    LSP_SERVERS_CONFIG,
  );
  if (commands.length === 0) {
    return errorResult("No LSP servers are configured for that file.");
  }

  const { result, errors } = await requestFromCandidateClients(
    commands,
    ctx,
    lspClients,
    async (client) =>
      client.getDocumentSymbols(
        targetFilePath,
        ctx.cwd,
        OPERATION_TIMEOUT_MS,
        signal,
      ),
    (symbols) => symbols.length > 0,
  );

  if (!result || result.length === 0) {
    if (errors.length > 0) {
      return errorResult(
        `Document symbol lookup failed: ${errors.join(" | ")}`,
      );
    }

    return successResult(
      `No document symbols found in ${displayPath(targetFilePath, ctx.cwd)}.`,
      {
        operation: "document_symbols",
        targetPath: targetFilePath,
        resultCount: 0,
      },
    );
  }

  return successResult(
    formatDocumentSymbolResult(displayPath(targetFilePath, ctx.cwd), result),
    {
      operation: "document_symbols",
      targetPath: targetFilePath,
      resultCount: result.length,
    },
  );
}

async function runDefinition(
  input: LspToolInput,
  signal: AbortSignal | undefined,
  ctx: ExtensionContext,
  lspClients: Map<string, LspClientEntry>,
  savedConfig: SavedConfig | null,
): Promise<ToolResult> {
  const targetFilePath = requireExistingFilePath(
    input.path,
    ctx.cwd,
    "definition",
  );
  if (targetFilePath instanceof Error) {
    return errorResult(targetFilePath.message);
  }

  const position = requirePosition(input);
  if (position instanceof Error) {
    return errorResult(position.message);
  }

  const commands = resolveFileCommands(
    targetFilePath,
    savedConfig,
    LSP_SERVERS_CONFIG,
  );
  if (commands.length === 0) {
    return errorResult("No LSP servers are configured for that file.");
  }

  const { result, errors } = await requestFromCandidateClients(
    commands,
    ctx,
    lspClients,
    async (client) =>
      normalizeLocationResult(
        await client.getDefinition(
          targetFilePath,
          position,
          ctx.cwd,
          OPERATION_TIMEOUT_MS,
          signal,
        ),
      ),
    (locations) => locations.length > 0,
  );

  if (!result || result.length === 0) {
    if (errors.length > 0) {
      return errorResult(`Definition lookup failed: ${errors.join(" | ")}`);
    }

    return successResult(
      `No definition found for ${displayPath(targetFilePath, ctx.cwd)}:${input.line}:${input.character}.`,
      {
        operation: "definition",
        targetPath: targetFilePath,
        resultCount: 0,
      },
    );
  }

  return successResult(
    formatLocationResult(result, ctx.cwd, {
      title: "Definition",
      maxResults: input.maxResults ?? DEFAULT_MAX_RESULTS,
    }),
    {
      operation: "definition",
      targetPath: targetFilePath,
      resultCount: result.length,
    },
  );
}

async function runReferences(
  input: LspToolInput,
  signal: AbortSignal | undefined,
  ctx: ExtensionContext,
  lspClients: Map<string, LspClientEntry>,
  savedConfig: SavedConfig | null,
): Promise<ToolResult> {
  const targetFilePath = requireExistingFilePath(
    input.path,
    ctx.cwd,
    "references",
  );
  if (targetFilePath instanceof Error) {
    return errorResult(targetFilePath.message);
  }

  const position = requirePosition(input);
  if (position instanceof Error) {
    return errorResult(position.message);
  }

  const commands = resolveFileCommands(
    targetFilePath,
    savedConfig,
    LSP_SERVERS_CONFIG,
  );
  if (commands.length === 0) {
    return errorResult("No LSP servers are configured for that file.");
  }

  const { result, errors } = await requestFromCandidateClients(
    commands,
    ctx,
    lspClients,
    async (client) =>
      client.getReferences(
        targetFilePath,
        position,
        input.includeDeclaration ?? false,
        ctx.cwd,
        OPERATION_TIMEOUT_MS,
        signal,
      ),
    (locations) => locations.length > 0,
  );

  if (!result || result.length === 0) {
    if (errors.length > 0) {
      return errorResult(`Reference lookup failed: ${errors.join(" | ")}`);
    }

    return successResult(
      `No references found for ${displayPath(targetFilePath, ctx.cwd)}:${input.line}:${input.character}.`,
      {
        operation: "references",
        targetPath: targetFilePath,
        resultCount: 0,
      },
    );
  }

  return successResult(
    formatLocationResult(result, ctx.cwd, {
      title: "References",
      maxResults: input.maxResults ?? DEFAULT_MAX_RESULTS,
    }),
    {
      operation: "references",
      targetPath: targetFilePath,
      resultCount: result.length,
      includeDeclaration: input.includeDeclaration ?? false,
    },
  );
}

async function runRename(
  input: LspToolInput,
  signal: AbortSignal | undefined,
  ctx: ExtensionContext,
  lspClients: Map<string, LspClientEntry>,
  savedConfig: SavedConfig | null,
): Promise<ToolResult> {
  const targetFilePath = requireExistingFilePath(input.path, ctx.cwd, "rename");
  if (targetFilePath instanceof Error) {
    return errorResult(targetFilePath.message);
  }

  const position = requirePosition(input);
  if (position instanceof Error) {
    return errorResult(position.message);
  }

  const newName = input.newName?.trim();
  if (!newName) {
    return errorResult("rename requires a non-empty newName.");
  }

  const commands = resolveFileCommands(
    targetFilePath,
    savedConfig,
    LSP_SERVERS_CONFIG,
  );
  if (commands.length === 0) {
    return errorResult("No LSP servers are configured for that file.");
  }

  const { result, errors } = await requestFromCandidateClients(
    commands,
    ctx,
    lspClients,
    async (client) =>
      client.renameSymbol(
        targetFilePath,
        position,
        newName,
        ctx.cwd,
        OPERATION_TIMEOUT_MS,
        signal,
      ),
    hasWorkspaceEditChanges,
  );

  if (!result || !hasWorkspaceEditChanges(result)) {
    if (errors.length > 0) {
      return errorResult(`Rename failed: ${errors.join(" | ")}`);
    }

    return successResult(
      `The LSP server did not return any rename edits for ${displayPath(targetFilePath, ctx.cwd)}:${input.line}:${input.character}.`,
      {
        operation: "rename",
        targetPath: targetFilePath,
        changedPathCount: 0,
      },
    );
  }

  const summary = applyWorkspaceEdit(result, ctx.cwd);
  const changedPaths = summary.changedPaths
    .slice(0, input.maxResults ?? DEFAULT_MAX_RESULTS)
    .map((changedPath) => `- ${displayPath(changedPath, ctx.cwd)}`);
  const remainingPaths = summary.changedPaths.length - changedPaths.length;
  const overflowLine =
    remainingPaths > 0 ? `\n... ${remainingPaths} more changed path(s)` : "";
  const renameFileLine =
    summary.renameCount > 0 ? `, ${summary.renameCount} file rename(s)` : "";

  return successResult(
    [
      `Renamed symbol to ${JSON.stringify(newName)}.`,
      `${summary.textDocumentCount} file(s) updated, ${summary.textEditCount} text edit(s) applied${renameFileLine}.`,
      changedPaths.length > 0
        ? `Changed paths:\n${changedPaths.join("\n")}${overflowLine}`
        : "",
    ]
      .filter(Boolean)
      .join("\n\n"),
    {
      operation: "rename",
      targetPath: targetFilePath,
      newName,
      changedPathCount: summary.changedPaths.length,
      textDocumentCount: summary.textDocumentCount,
      textEditCount: summary.textEditCount,
      renameCount: summary.renameCount,
    },
  );
}

async function requestFromCandidateClients<T>(
  commands: ReturnType<typeof resolveFileCommands>,
  ctx: ExtensionContext,
  lspClients: Map<string, LspClientEntry>,
  request: (client: LspClientEntry["client"]) => Promise<T>,
  hasUsableResult: (result: T) => boolean,
): Promise<CandidateRequestResult<T>> {
  syncLspServers(
    ctx,
    commands.map(({ resolved }) => path.basename(resolved.command[0]!)),
  );

  const errors: string[] = [];
  let lastResult: T | null = null;

  for (const command of commands) {
    let commandKey = "";
    try {
      const activeClient = await getOrCreateLspClient(
        command.resolved,
        command.rootSourcePath,
        ctx,
        lspClients,
      );
      commandKey = activeClient.commandKey;
      setLspWidget(ctx, activeClient.entry.bin, "collecting");

      const result = await request(activeClient.entry.client);
      lastResult = result;
      setLspWidget(ctx, activeClient.entry.bin, "idle");

      if (hasUsableResult(result)) {
        return { result, errors };
      }
    } catch (err) {
      errors.push(err instanceof Error ? err.message : String(err));
      handleLspClientError(err, commandKey, ctx, lspClients);
    }
  }

  return { result: lastResult, errors };
}

function requireExistingFilePath(
  inputPath: string | undefined,
  cwd: string,
  operation: string,
): string | Error {
  if (!inputPath?.trim()) {
    return new Error(`${operation} requires a file path.`);
  }

  const resolvedPath = path.resolve(cwd, inputPath);
  if (!fs.existsSync(resolvedPath)) {
    return new Error(`Path not found: ${inputPath}`);
  }

  if (!fs.statSync(resolvedPath).isFile()) {
    return new Error(`${operation} requires a file path, not a directory.`);
  }

  return resolvedPath;
}

function requirePosition(input: LspToolInput) {
  if (input.line == null || input.character == null) {
    return new Error("line and character are required for this LSP operation.");
  }

  try {
    return toLspPosition(input.line, input.character);
  } catch (err) {
    return err instanceof Error ? err : new Error(String(err));
  }
}

function hasWorkspaceEditChanges(value: unknown): boolean {
  if (!value || typeof value !== "object") return false;
  const workspaceEdit = value as {
    changes?: Record<string, unknown[]>;
    documentChanges?: unknown[];
  };

  return (
    Object.keys(workspaceEdit.changes ?? {}).length > 0 ||
    (workspaceEdit.documentChanges?.length ?? 0) > 0
  );
}

function dedupeWorkspaceSymbols(
  symbols: Awaited<ReturnType<LspClientEntry["client"]["getWorkspaceSymbols"]>>,
) {
  const seen = new Set<string>();
  return symbols.filter((symbol) => {
    const location = symbol.location;
    const key = location
      ? `${symbol.name}:${location.uri}:${location.range.start.line}:${location.range.start.character}`
      : `${symbol.name}:${symbol.containerName ?? ""}:${symbol.kind}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function displayPath(targetPath: string, cwd: string): string {
  const relativePath = path.relative(cwd, targetPath);
  return relativePath === "" ? "." : relativePath;
}

function successResult(
  text: string,
  details: Record<string, unknown> = {},
): ToolResult {
  return {
    content: [{ type: "text", text }],
    details,
  };
}

function errorResult(text: string): ToolResult {
  return {
    content: [{ type: "text", text: `Error: ${text}` }],
    details: { error: text },
  };
}
