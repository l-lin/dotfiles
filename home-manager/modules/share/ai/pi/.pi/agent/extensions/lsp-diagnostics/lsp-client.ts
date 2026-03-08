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
import type { LspDiagnostic, PublishDiagnosticsParams } from "./types.js";
import { pathToFileUri, guessLanguageId } from "./resolver.js";

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

export class PersistentLspClient {
  private connection;
  private proc;
  private diagnosticsMap = new Map<string, LspDiagnostic[]>();
  // Resolvers waiting for a fresh publishDiagnostics notification for a URI
  private waiters = new Map<string, Array<() => void>>();
  private openedFiles = new Set<string>();
  // Incremented per didChange to satisfy LSP version monotonicity
  private versionCounter = 1;
  private onError?: NotifyFn;

  // ── Timing metrics ──
  /** Time taken for LSP initialization (spawn + initialize handshake) */
  public initDurationMs: number = 0;
  /** Last getDiagnostics result timing */
  public lastCheckDurationMs: number = 0;
  /** Whether last check received response or timed out */
  public lastCheckReceivedResponse: boolean = false;
  /** Total publishDiagnostics notifications received */
  public totalNotificationsReceived: number = 0;

  // ── Debug info ──
  /** URIs we're currently waiting for */
  public pendingUris: string[] = [];
  /** Last N URIs received from publishDiagnostics (for debugging) */
  public receivedUris: string[] = [];
  /** Last URI mismatch debug info */
  public lastMismatchInfo: string | null = null;

  private constructor(
    proc: ReturnType<typeof spawn>,
    connection: ReturnType<typeof createMessageConnection>,
    onError?: NotifyFn,
  ) {
    this.proc = proc;
    this.connection = connection;
    this.onError = onError;

    connection.onNotification(
      "textDocument/publishDiagnostics",
      (params: PublishDiagnosticsParams) => {
        this.totalNotificationsReceived++;

        // Track received URIs for debugging (keep last 10)
        this.receivedUris.push(params.uri);
        if (this.receivedUris.length > 10) this.receivedUris.shift();

        this.diagnosticsMap.set(params.uri, params.diagnostics);
        const resolvers = this.waiters.get(params.uri) ?? [];

        // Debug: check for URI mismatch
        if (resolvers.length === 0 && this.waiters.size > 0) {
          const waiting = [...this.waiters.keys()];
          this.lastMismatchInfo = `Received: ${params.uri}\nWaiting for: ${waiting.join(", ")}`;
        }

        this.waiters.delete(params.uri);
        resolvers.forEach((r) => r());
      },
    );
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

    const client = new PersistentLspClient(proc, connection, onError);

    const defaultCapabilities = {
      textDocument: { publishDiagnostics: { relatedInformation: false } },
      workspace: { workspaceFolders: true },
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
        workspaceFolders: [
          { uri: pathToFileUri(projectRoot), name: path.basename(projectRoot) },
        ],
      }),
    ]);

    connection.sendNotification("initialized", {});

    // Push server-specific settings immediately after handshake
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
    const uris = filePaths.map((f) => pathToFileUri(path.resolve(cwd, f)));

    // Track pending URIs for debugging
    this.pendingUris = [...uris];
    this.lastMismatchInfo = null;

    // Track which URIs received responses
    const resolvedUris = new Set<string>();

    // Register waiters before sending notifications to avoid missing fast responses
    const diagnosticsReady = Promise.all(
      uris.map(
        (uri) =>
          new Promise<void>((resolve) => {
            const existing = this.waiters.get(uri) ?? [];
            existing.push(() => {
              resolvedUris.add(uri);
              resolve();
            });
            this.waiters.set(uri, existing);
          }),
      ),
    );

    for (let i = 0; i < filePaths.length; i++) {
      const absPath = path.resolve(cwd, filePaths[i]!);
      const uri = uris[i]!;
      let text = "";
      try {
        text = fs.readFileSync(absPath, "utf8");
      } catch {
        /* let the LSP report the error */
      }

      if (!this.openedFiles.has(uri)) {
        // First open: send didOpen and wait for diagnostics
        this.openedFiles.add(uri);
        this.connection.sendNotification("textDocument/didOpen", {
          textDocument: {
            uri,
            languageId: guessLanguageId(absPath),
            version: this.versionCounter++,
            text,
          },
        });
      } else {
        // Already open: send didChange + didSave, but also immediately resolve
        // the waiter since we already have cached diagnostics. Some LSP servers
        // (like vtsls) don't send publishDiagnostics for clean files.
        const version = this.versionCounter++;
        this.connection.sendNotification("textDocument/didChange", {
          textDocument: { uri, version },
          contentChanges: [{ text }],
        });
        this.connection.sendNotification("textDocument/didSave", {
          textDocument: { uri },
          text,
        });

        // Immediately resolve waiter for already-open files — use cached diagnostics
        // The LSP will push updates if diagnostics change
        const waiters = this.waiters.get(uri) ?? [];
        this.waiters.delete(uri);
        resolvedUris.add(uri);
        waiters.forEach((r) => r());
      }
    }

    // Race: all diagnostics arrive OR timeout OR abort
    // Use a sentinel to detect which promise won
    const TIMEOUT_SENTINEL = Symbol("timeout");
    const ABORT_SENTINEL = Symbol("abort");

    const timeout = new Promise<symbol>((resolve) =>
      setTimeout(() => resolve(TIMEOUT_SENTINEL), timeoutMs),
    );
    const aborted = signal
      ? new Promise<symbol>((resolve) =>
          signal.addEventListener("abort", () => resolve(ABORT_SENTINEL), {
            once: true,
          }),
        )
      : null;

    const raceResult = await Promise.race([
      diagnosticsReady.then(() => "resolved" as const),
      timeout,
      ...(aborted ? [aborted] : []),
    ]);

    const receivedResponse = raceResult === "resolved";
    const durationMs = Date.now() - startTime;

    // Clear any stale waiters that timed out
    for (const uri of uris) {
      this.waiters.delete(uri);
    }

    // Clean up empty diagnostic entries to prevent accumulation of stale data
    this.cleanupEmptyDiagnostics();

    const result = new Map<string, LspDiagnostic[]>();
    for (const uri of uris) {
      result.set(uri, this.diagnosticsMap.get(uri) ?? []);
    }

    // Update timing metrics
    this.lastCheckDurationMs = durationMs;
    this.lastCheckReceivedResponse = receivedResponse;

    return {
      diagnostics: result,
      durationMs,
      receivedResponse,
      urisResolved: resolvedUris.size,
      urisRequested: uris.length,
    };
  }

  /**
   * Removes diagnostic entries for files with empty diagnostic arrays.
   * Call this periodically to prevent stale diagnostics from accumulating.
   */
  cleanupEmptyDiagnostics(): void {
    for (const [uri, diags] of this.diagnosticsMap.entries()) {
      if (diags.length === 0) {
        this.diagnosticsMap.delete(uri);
      }
    }
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
      lastCheckDurationMs: this.lastCheckDurationMs,
      lastCheckReceivedResponse: this.lastCheckReceivedResponse,
      totalNotificationsReceived: this.totalNotificationsReceived,
      pendingUris: [...this.pendingUris],
      receivedUris: [...this.receivedUris],
      lastMismatchInfo: this.lastMismatchInfo,
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
