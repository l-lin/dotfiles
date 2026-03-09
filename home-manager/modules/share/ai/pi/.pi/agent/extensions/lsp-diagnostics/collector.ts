/**
 * Shared fan-out → merge orchestration for LSP diagnostics collection.
 * Used by both the tool_result event handler and the lsp-check command.
 */
import * as path from "node:path";
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { LspDiagnostic, LspClientEntry } from "./types.js";
import type { ResolvedLspCommand } from "./resolver.js";
import { resolveRootDir } from "./resolver.js";
import { PersistentLspClient } from "./client/persistent-client.js";
import { setLspWidget, clearWidget, syncLspServers } from "./ui/widget.js";

const DIAGNOSTICS_TIMEOUT_MS = 5_000;

export interface TimingInfo {
  initDurationMs: number;
  lastCheckDurationMs: number;
  receivedResponse: boolean;
}

export interface ServerResult {
  bin: string;
  diagnostics: Map<string, LspDiagnostic[]>;
  timing: TimingInfo;
}

export interface CollectResult {
  merged: Map<string, LspDiagnostic[]>;
  servers: ServerResult[];
}

export async function getOrCreateClient(
  resolved: ResolvedLspCommand,
  rootDir: string,
  commandKey: string,
  lspBin: string,
  ctx: ExtensionContext,
  lspClients: Map<string, LspClientEntry>,
): Promise<LspClientEntry> {
  setLspWidget(ctx, lspBin, "starting");

  const existing = lspClients.get(commandKey);
  if (existing) return existing;

  const client = await PersistentLspClient.create(
    resolved.command,
    ctx.cwd,
    (msg, severity = "info") => ctx.ui.notify(msg, severity),
    rootDir,
    resolved.settings,
    resolved.capabilities,
  );

  const entry: LspClientEntry = {
    client,
    bin: lspBin,
    command: resolved.command,
    rootDir,
    settings: resolved.settings,
    startedAt: new Date(),
  };
  lspClients.set(commandKey, entry);
  return entry;
}

export function handleLspError(
  err: unknown,
  commandKey: string,
  ctx: ExtensionContext,
  lspClients: Map<string, LspClientEntry>,
): void {
  lspClients.delete(commandKey);
  if (lspClients.size === 0) {
    clearWidget(ctx);
  } else {
    const [survivingEntry] = lspClients.values();
    setLspWidget(ctx, survivingEntry!.bin, "idle");
  }
  ctx.ui.notify(
    `lsp-diagnostics: ${err instanceof Error ? err.message : String(err)}`,
    "warning",
  );
}

/**
 * Fan out diagnostics requests to all matching LSP servers, merge results.
 * Shared by the tool_result handler and lsp-check command.
 */
export async function collectDiagnostics(
  files: string[],
  resolvedList: ResolvedLspCommand[],
  lspClients: Map<string, LspClientEntry>,
  ctx: ExtensionContext,
): Promise<CollectResult> {
  if (files.length === 0) return { merged: new Map(), servers: [] };

  const merged = new Map<string, LspDiagnostic[]>();
  const servers: ServerResult[] = [];
  const orderedBins = resolvedList.map((r) => path.basename(r.command[0]!));

  syncLspServers(ctx, orderedBins);

  await Promise.all(
    resolvedList.map(async (resolved) => {
      const rootDir =
        resolved.rootMarkers.length > 0
          ? resolveRootDir(files[0]!, resolved.rootMarkers, ctx.cwd)
          : ctx.cwd;
      const commandKey = `${resolved.command.join(" ")}::${rootDir}`;
      const lspBin = path.basename(resolved.command[0]!);

      let entry: LspClientEntry;
      try {
        entry = await getOrCreateClient(
          resolved,
          rootDir,
          commandKey,
          lspBin,
          ctx,
          lspClients,
        );
      } catch (err) {
        handleLspError(err, commandKey, ctx, lspClients);
        return;
      }

      setLspWidget(ctx, lspBin, "collecting");

      let result;
      try {
        result = await entry.client.getDiagnostics(
          files,
          ctx.cwd,
          DIAGNOSTICS_TIMEOUT_MS,
          AbortSignal.timeout(DIAGNOSTICS_TIMEOUT_MS),
        );
      } catch (err) {
        handleLspError(err, commandKey, ctx, lspClients);
        return;
      }

      if (!result.receivedResponse) {
        ctx.ui.notify(
          `lsp-diagnostics: ${lspBin} timed out after ${result.durationMs}ms (${result.urisResolved}/${result.urisRequested} files)`,
          "warning",
        );
      }

      const timing: TimingInfo = {
        initDurationMs: entry.client.initDurationMs,
        lastCheckDurationMs: result.durationMs,
        receivedResponse: result.receivedResponse,
      };

      servers.push({ bin: lspBin, diagnostics: result.diagnostics, timing });
      setLspWidget(ctx, lspBin, "idle", result.diagnostics, timing);

      for (const [uri, diags] of result.diagnostics) {
        const existing = merged.get(uri) ?? [];
        merged.set(uri, [...existing, ...diags]);
      }
    }),
  );

  return { merged, servers };
}
