/**
 * Persistent LSP client: initialize once, reuse across file writes, shutdown on session end.
 */
import { spawn } from "node:child_process";
import * as path from "node:path";
import * as fs from "node:fs";
import {
  createMessageConnection,
  StreamMessageReader,
  StreamMessageWriter,
} from "vscode-jsonrpc/node.js";
import type { LspDiagnostic, PublishDiagnosticsParams } from "../types.js";
import {
  pathToFileUri,
  pathToCanonicalUri,
  canonicalizeUri,
  fileUriToPath,
  guessLanguageId,
} from "../resolver.js";

type NotifyFn = (msg: string, severity?: "info" | "warning" | "error") => void;

/** Recursively merges `override` into `base`, with override values winning on conflicts. */
function deepMerge(
  base: Record<string, unknown>,
  override: Record<string, unknown>,
): Record<string, unknown> {
  const result: Record<string, unknown> = { ...base };
  for (const [key, val] of Object.entries(override)) {
    if (
      val !== null &&
      typeof val === "object" &&
      !Array.isArray(val) &&
      typeof base[key] === "object" &&
      base[key] !== null &&
      !Array.isArray(base[key])
    ) {
      result[key] = deepMerge(
        base[key] as Record<string, unknown>,
        val as Record<string, unknown>,
      );
    } else {
      result[key] = val;
    }
  }
  return result;
}

/** Result of getDiagnostics with timing metadata */
export interface DiagnosticsResult {
  diagnostics: Map<string, LspDiagnostic[]>;
  /** Time in ms from request to response */
  durationMs: number;
  /** True if we received publishDiagnostics, false if timed out */
  receivedResponse: boolean;
  /** Number of URIs that received diagnostics */
  urisResolved: number;
  /** Total URIs requested */
  urisRequested: number;
}

interface FileInfo {
  absPath: string;
  canonicalUri: string;
  rawUri: string;
}

export class PersistentLspClient {
  private connection;
  private proc;
  private diagnosticsMap = new Map<string, LspDiagnostic[]>();
  // Resolvers waiting for a fresh publishDiagnostics notification for a URI
  private waiters = new Map<string, Array<() => void>>();
  private openedFiles = new Set<string>();
  // Incremented per didChange to satisfy LSP version monotonicity
  private versionCounter = 1;

  /** Time taken for LSP initialization (spawn + initialize handshake) */
  public initDurationMs: number = 0;

  private debugState = {
    pendingUris: [] as string[],
    receivedUris: [] as string[], // circular buffer, last 10
    lastMismatchInfo: null as string | null,
    totalNotificationsReceived: 0,
    lastNotificationTime: 0,
    lastCheckDurationMs: 0,
    lastCheckReceivedResponse: false,
  };

  private serverSettings: Record<string, unknown> | undefined;

  private constructor(
    proc: ReturnType<typeof spawn>,
    connection: ReturnType<typeof createMessageConnection>,
    settings?: Record<string, unknown>,
    _notify?: NotifyFn,
  ) {
    this.proc = proc;
    this.connection = connection;
    this.serverSettings = settings;

    // Handle workspace/configuration requests (pull model).
    // Many servers (like lua-language-server) request configuration instead of
    // relying on didChangeConfiguration notifications.
    connection.onRequest("workspace/configuration", (params: any) => {
      const items = params.items || [];
      return items.map((item: any) => {
        if (item.section && this.serverSettings) {
          return this.serverSettings[item.section] ?? null;
        }
        return this.serverSettings ?? null;
      });
    });

    connection.onNotification(
      "textDocument/publishDiagnostics",
      (params: PublishDiagnosticsParams) => {
        this.debugState.totalNotificationsReceived++;
        this.debugState.lastNotificationTime = Date.now();

        this.debugState.receivedUris.push(params.uri);
        if (this.debugState.receivedUris.length > 10) {
          this.debugState.receivedUris.shift();
        }

        const rawUri = params.uri;
        this.diagnosticsMap.set(rawUri, params.diagnostics);

        const canonicalUri = canonicalizeUri(rawUri);
        if (canonicalUri !== rawUri) {
          this.diagnosticsMap.set(canonicalUri, params.diagnostics);
        }

        const match = this.resolveWaiter(rawUri);
        if (match) {
          this.diagnosticsMap.set(match.matchedUri, params.diagnostics);
          this.waiters.delete(match.matchedUri);
          match.resolvers.forEach((r) => r());
        } else if (this.waiters.size > 0) {
          // Flag mismatch only when the same filename is being waited for —
          // receiving diagnostics for unrelated files is normal LSP behavior.
          const incomingFilename = path.basename(fileUriToPath(params.uri));
          const sameFilenameWaiters = [...this.waiters.keys()].filter(
            (uri) => path.basename(fileUriToPath(uri)) === incomingFilename,
          );
          if (sameFilenameWaiters.length > 0) {
            this.debugState.lastMismatchInfo =
              `Received: ${params.uri}\nCanonical: ${canonicalUri}\n` +
              `Waiting for: ${sameFilenameWaiters.join(", ")}`;
          }
        }
      },
    );
  }

  /**
   * Tries to match an incoming URI against registered waiters using three strategies:
   * 1. Raw URI (exact match from server)
   * 2. Canonical URI (symlinks resolved)
   * 3. Filename + path suffix (handles different project root prefixes)
   */
  private resolveWaiter(
    rawUri: string,
  ): { resolvers: Array<() => void>; matchedUri: string } | null {
    const canonicalUri = canonicalizeUri(rawUri);

    // Strategy 1: exact raw URI
    let resolvers = this.waiters.get(rawUri);
    if (resolvers?.length) return { resolvers, matchedUri: rawUri };

    // Strategy 2: canonical URI (symlink resolution)
    resolvers = this.waiters.get(canonicalUri);
    if (resolvers?.length) return { resolvers, matchedUri: canonicalUri };

    // Strategy 3: filename + path suffix match
    const incomingPath = fileUriToPath(rawUri);
    const incomingFilename = path.basename(incomingPath);
    const incomingSegments = incomingPath.split("/").slice(-3).join("/");

    for (const [waitingUri, waiters] of this.waiters.entries()) {
      const waitingPath = fileUriToPath(waitingUri);
      if (
        path.basename(waitingPath) === incomingFilename &&
        (incomingPath.endsWith(waitingPath) ||
          waitingPath.endsWith(incomingPath) ||
          incomingSegments === waitingPath.split("/").slice(-3).join("/"))
      ) {
        return { resolvers: waiters, matchedUri: waitingUri };
      }
    }

    return null;
  }

  private resolveFileInfo(filePaths: string[], cwd: string): FileInfo[] {
    return filePaths.map((f) => {
      const absPath = path.resolve(cwd, f);
      return {
        absPath,
        canonicalUri: pathToCanonicalUri(absPath),
        rawUri: pathToFileUri(absPath),
      };
    });
  }

  /** Register waiters for canonical + raw URIs. Returns a cleanup function. */
  private registerWaiters(
    uris: string[],
    rawUris: string[],
    resolvedUris: Set<string>,
  ): () => void {
    for (let i = 0; i < uris.length; i++) {
      const canonicalUri = uris[i]!;
      const rawUri = rawUris[i]!;

      const resolver = () => resolvedUris.add(canonicalUri);

      const existingCanonical = this.waiters.get(canonicalUri) ?? [];
      existingCanonical.push(resolver);
      this.waiters.set(canonicalUri, existingCanonical);

      if (rawUri !== canonicalUri) {
        const existingRaw = this.waiters.get(rawUri) ?? [];
        existingRaw.push(resolver);
        this.waiters.set(rawUri, existingRaw);
      }
    }

    return () => {
      for (const uri of uris) this.waiters.delete(uri);
      for (const uri of rawUris) this.waiters.delete(uri);
    };
  }

  private sendFileNotifications(fileInfo: FileInfo[]): void {
    for (const { absPath, canonicalUri } of fileInfo) {
      let text = "";
      try {
        text = fs.readFileSync(absPath, "utf8");
      } catch {
        /* let the LSP report the error */
      }

      if (!this.openedFiles.has(canonicalUri)) {
        this.openedFiles.add(canonicalUri);
        this.connection.sendNotification("textDocument/didOpen", {
          textDocument: {
            uri: canonicalUri,
            languageId: guessLanguageId(absPath),
            version: this.versionCounter++,
            text,
          },
        });
      } else {
        const version = this.versionCounter++;
        this.connection.sendNotification("textDocument/didChange", {
          textDocument: { uri: canonicalUri, version },
          contentChanges: [{ text }],
        });
        this.connection.sendNotification("textDocument/didSave", {
          textDocument: { uri: canonicalUri },
          text,
        });
      }
    }
  }

  private buildResult(
    uris: string[],
    rawUris: string[],
    resolvedUris: Set<string>,
    startTime: number,
    receivedResponse: boolean,
  ): DiagnosticsResult {
    const result = new Map<string, LspDiagnostic[]>();
    for (let i = 0; i < uris.length; i++) {
      const canonicalUri = uris[i]!;
      const rawUri = rawUris[i]!;
      let diags = this.diagnosticsMap.get(canonicalUri);
      if (diags === undefined && rawUri !== canonicalUri) {
        diags = this.diagnosticsMap.get(rawUri);
      }
      result.set(canonicalUri, diags ?? []);
    }

    const durationMs = Date.now() - startTime;
    this.debugState.lastCheckDurationMs = durationMs;
    this.debugState.lastCheckReceivedResponse = receivedResponse;

    return {
      diagnostics: result,
      durationMs,
      receivedResponse,
      urisResolved: resolvedUris.size,
      urisRequested: uris.length,
    };
  }

  /**
   * Poll until all URIs have responses, grace period expires, or timeout.
   *
   * Grace period: if the server responded for other files but has been silent
   * for 500ms, the file is likely clean.
   * Cold start: if no diagnostics after 1.5s, assume file is clean.
   */
  private async waitForDiagnostics(
    uris: string[],
    resolvedUris: Set<string>,
    timeoutMs: number,
    notifCountAfterSend: number,
    notifTimeAfterSend: number,
    signal?: AbortSignal,
  ): Promise<boolean> {
    const GRACE_PERIOD_MS = 500;
    const POLL_INTERVAL_MS = 100;
    const startTime = Date.now();

    while (true) {
      if (signal?.aborted) return false;

      const allResolved = uris.every(
        (uri) => !this.waiters.has(uri) || resolvedUris.has(uri),
      );
      if (allResolved) return true;

      const elapsed = Date.now() - startTime;
      if (elapsed >= timeoutMs) return false;

      // Grace period: server responded for other files but silent for ours
      const serverActiveAfterSend =
        this.debugState.totalNotificationsReceived > notifCountAfterSend &&
        this.debugState.lastNotificationTime > notifTimeAfterSend;
      if (
        serverActiveAfterSend &&
        Date.now() - this.debugState.lastNotificationTime >= GRACE_PERIOD_MS
      ) {
        return true;
      }

      // Cold start: no diagnostics after 1.5s likely means file is clean
      if (elapsed >= 1500) return true;

      await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
    }
  }

  static async create(
    lspCommand: string[],
    cwd: string,
    onError?: NotifyFn,
    /** Project root to advertise as rootUri (defaults to cwd). */
    rootDir?: string,
    /** Arbitrary settings forwarded via workspace/didChangeConfiguration after init. */
    settings?: Record<string, unknown>,
    /** Custom client capabilities merged into the default initialize capabilities. */
    capabilities?: Record<string, unknown>,
  ): Promise<PersistentLspClient> {
    const initStart = Date.now();
    const projectRoot = rootDir ?? cwd;
    const [cmd, ...args] = lspCommand;
    const proc = spawn(cmd!, args, {
      cwd: projectRoot,
      stdio: ["pipe", "pipe", "pipe"],
    });

    // Silently swallow writes to a destroyed stdin (vscode-jsonrpc flushes async)
    if (proc.stdin) {
      const _origWrite = proc.stdin.write.bind(proc.stdin);
      (proc.stdin as any).write = (
        chunk: any,
        encodingOrCb?: any,
        cb?: any,
      ): boolean => {
        if (proc.stdin!.destroyed) {
          const callback =
            typeof encodingOrCb === "function" ? encodingOrCb : cb;
          if (typeof callback === "function") process.nextTick(callback, null);
          return false;
        }
        return _origWrite(chunk, encodingOrCb, cb);
      };
      proc.stdin.on("error", (err) =>
        onError?.(`lsp-diagnostics: stdin error — ${err.message}`, "info"),
      );
    }

    // Reject the race if the process fails to spawn — propagates to create() caller
    const spawnError = new Promise<never>((_, reject) => {
      proc.on("error", reject);
    });

    const connection = createMessageConnection(
      new StreamMessageReader(proc.stdout!),
      new StreamMessageWriter(proc.stdin!),
    );
    connection.listen();

    const client = new PersistentLspClient(proc, connection, settings, onError);

    const defaultCapabilities = {
      textDocument: { publishDiagnostics: { relatedInformation: false } },
      workspace: { workspaceFolders: true, configuration: true },
    };
    const initCapabilities = capabilities
      ? deepMerge(defaultCapabilities, capabilities)
      : defaultCapabilities;

    await Promise.race([
      spawnError,
      connection.sendRequest("initialize", {
        processId: process.pid,
        rootUri: pathToFileUri(projectRoot),
        capabilities: initCapabilities,
        initializationOptions: settings,
        workspaceFolders: [
          { uri: pathToFileUri(projectRoot), name: path.basename(projectRoot) },
        ],
      }),
    ]);

    connection.sendNotification("initialized", {});

    // Push server-specific settings immediately after handshake (push model).
    // Note: servers like lua-language-server prefer the pull model
    // (workspace/configuration request), handled by the onRequest handler above.
    if (settings && Object.keys(settings).length > 0) {
      connection.sendNotification("workspace/didChangeConfiguration", {
        settings,
      });
    }

    client.initDurationMs = Date.now() - initStart;
    return client;
  }

  /**
   * Notifies the LSP of file changes and waits for fresh diagnostics.
   * - First open: sends didOpen
   * - Subsequent: sends didChange + didSave
   */
  async getDiagnostics(
    filePaths: string[],
    cwd: string,
    timeoutMs: number,
    signal?: AbortSignal,
  ): Promise<DiagnosticsResult> {
    const startTime = Date.now();
    const fileInfo = this.resolveFileInfo(filePaths, cwd);
    const uris = fileInfo.map((f) => f.canonicalUri);
    const rawUris = fileInfo.map((f) => f.rawUri);
    const resolvedUris = new Set<string>();

    this.debugState.pendingUris = [...uris];
    this.debugState.lastMismatchInfo = null;

    const waiterCleanup = this.registerWaiters(uris, rawUris, resolvedUris);

    const notifCountAfterSend = this.debugState.totalNotificationsReceived;
    const notifTimeAfterSend = this.debugState.lastNotificationTime;

    this.sendFileNotifications(fileInfo);

    const receivedResponse = await this.waitForDiagnostics(
      uris,
      resolvedUris,
      timeoutMs,
      notifCountAfterSend,
      notifTimeAfterSend,
      signal,
    );

    waiterCleanup();

    if (
      !receivedResponse &&
      this.debugState.totalNotificationsReceived > notifCountAfterSend
    ) {
      const lastReceived = this.debugState.receivedUris.slice(-3).join(", ");
      this.debugState.lastMismatchInfo = `Timeout but server active. Last received: ${lastReceived}\nWaiting for: ${uris.join(", ")}`;
    }

    return this.buildResult(
      uris,
      rawUris,
      resolvedUris,
      startTime,
      receivedResponse,
    );
  }

  /**
   * Returns a snapshot of internal state for debugging purposes.
   */
  getDebugInfo(): {
    openedFiles: string[];
    diagnosticsMap: Map<string, LspDiagnostic[]>;
    versionCounter: number;
    pendingWaiters: string[];
    initDurationMs: number;
    lastCheckDurationMs: number;
    lastCheckReceivedResponse: boolean;
    totalNotificationsReceived: number;
    pendingUris: string[];
    receivedUris: string[];
    lastMismatchInfo: string | null;
  } {
    return {
      openedFiles: [...this.openedFiles],
      diagnosticsMap: new Map(
        [...this.diagnosticsMap.entries()].map(([k, v]) => [k, [...v]]),
      ),
      versionCounter: this.versionCounter,
      pendingWaiters: [...this.waiters.keys()],
      initDurationMs: this.initDurationMs,
      ...this.debugState,
      pendingUris: [...this.debugState.pendingUris],
      receivedUris: [...this.debugState.receivedUris],
    };
  }

  async shutdown(): Promise<void> {
    try {
      let timer: ReturnType<typeof setTimeout> | undefined;
      await Promise.race([
        this.connection.sendRequest("shutdown", null),
        new Promise((_, reject) => {
          timer = setTimeout(() => reject(new Error("shutdown timeout")), 3000);
        }),
      ]).finally(() => clearTimeout(timer));
      if (!this.proc.stdin?.destroyed) {
        this.connection.sendNotification("exit", {});
      }
    } catch {
      /* ignore shutdown errors */
    } finally {
      this.connection.dispose();
      this.proc.kill();
    }
  }
}
