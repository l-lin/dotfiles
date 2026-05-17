import * as path from "node:path";
import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import { PersistentLspClient } from "./client/persistent-client.js";
import type { LspClientEntry } from "./types.js";
import { resolveRootDir, type ResolvedLspCommand } from "./resolver.js";
import { clearWidget, setLspWidget } from "./ui/widget.js";

export interface ActiveLspClient {
  entry: LspClientEntry;
  commandKey: string;
}

export async function getOrCreateLspClient(
  resolved: ResolvedLspCommand,
  rootSourcePath: string,
  ctx: ExtensionContext,
  lspClients: Map<string, LspClientEntry>,
): Promise<ActiveLspClient> {
  const rootDir =
    resolved.rootMarkers.length > 0
      ? resolveRootDir(rootSourcePath, resolved.rootMarkers, ctx.cwd)
      : ctx.cwd;
  const commandKey = `${resolved.command.join(" ")}::${rootDir}`;
  const lspBin = path.basename(resolved.command[0]!);

  setLspWidget(ctx, lspBin, "starting");

  const existing = lspClients.get(commandKey);
  if (existing) {
    return { entry: existing, commandKey };
  }

  const client = await PersistentLspClient.create(
    resolved.command,
    ctx.cwd,
    (message, severity = "info") => ctx.ui.notify(message, severity),
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

  return { entry, commandKey };
}

export function handleLspClientError(
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
