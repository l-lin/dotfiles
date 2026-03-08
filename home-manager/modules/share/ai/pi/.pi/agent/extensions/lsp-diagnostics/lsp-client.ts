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
import {
  pathToFileUri,
  pathToCanonicalUri,
  canonicalizeUri,
  fileUriToPath,
  guessLanguageId,
} from "./resolver.js";

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

  // ── Timing metrics ──
  /** Time taken for LSP initialization (spawn + initialize handshake) */
  public initDurationMs: number = 0;
  /** Last getDiagnostics result timing */
  public lastCheckDurationMs: number = 0;
  /** Whether last check received response or timed out */
  public lastCheckReceivedResponse: boolean = false;
  /** Total publishDiagnostics notifications received */
  public totalNotificationsReceived: number = 0;
  /** Timestamp of last received publishDiagnostics notification */
  private lastNotificationTime: number = 0;

  // ── Debug info ──
  /** URIs we're currently waiting for */
  public pendingUris: string[] = [];
  /** Last N URIs received from publishDiagnostics (for debugging) */
  public receivedUris: string[] = [];
  /** Last URI mismatch debug info */
  public lastMismatchInfo: string | null = null;

  // Server settings passed during initialization
  private serverSettings: Record<string, unknown> | undefined;

  private constructor(
    proc: ReturnType<typeof spawn>,
    connection: ReturnType<typeof createMessageConnection>,
    settings?: Record<string, unknown>,
    notify?: NotifyFn,
  ) {
    this.proc = proc;
    this.connection = connection;
    this.serverSettings = settings;

    // Handle workspace/configuration requests (pull model)
    // Many language servers (like lua-language-server) request configuration
    // instead of relying on didChangeConfiguration notifications
    connection.onRequest("workspace/configuration", (params: any) => {
      // params.items is an array of ConfigurationItem
      // Each item has: { scopeUri?: string; section?: string; }
      const items = params.items || [];
      return items.map((item: any) => {
        // If section is specified (e.g., "Lua"), return that section
        // Otherwise return all settings
        if (item.section && this.serverSettings) {
          return this.serverSettings[item.section] ?? null;
        }
        return this.serverSettings ?? null;
      });
    });

    connection.onNotification(
      "textDocument/publishDiagnostics",
      (params: PublishDiagnosticsParams) => {
        this.totalNotificationsReceived++;
        this.lastNotificationTime = Date.now();

        // Track received URIs for debugging (keep last 10)
        this.receivedUris.push(params.uri);
        if (this.receivedUris.length > 10) this.receivedUris.shift();

        // Store diagnostics under the raw URI from the server
        const rawUri = params.uri;
        this.diagnosticsMap.set(rawUri, params.diagnostics);

        // Try to resolve waiters using multiple URI forms
        const canonicalUri = canonicalizeUri(rawUri);

        // Also store under canonical for consistent lookup later
        if (canonicalUri !== rawUri) {
          this.diagnosticsMap.set(canonicalUri, params.diagnostics);
        }

        // Try matching waiters: raw URI first, then canonical
        let resolvers = this.waiters.get(rawUri);
        let matchedUri = rawUri;

        if (!resolvers || resolvers.length === 0) {
          resolvers = this.waiters.get(canonicalUri);
          matchedUri = canonicalUri;
        }

        // If still no match, try filename-based matching as last resort
        // This handles cases where only the path prefix differs
        if (!resolvers || resolvers.length === 0) {
          const incomingPath = fileUriToPath(rawUri);
          const incomingFilename = path.basename(incomingPath);

          for (const [waitingUri, waiters] of this.waiters.entries()) {
            const waitingPath = fileUriToPath(waitingUri);
            const waitingFilename = path.basename(waitingPath);

            // Match by filename AND check that paths end the same way
            // (handles different project root prefixes)
            if (
              waitingFilename === incomingFilename &&
              (incomingPath.endsWith(waitingPath) ||
                waitingPath.endsWith(incomingPath) ||
                // Also check relative path suffix match (last 3 components)
                incomingPath.split("/").slice(-3).join("/") ===
                  waitingPath.split("/").slice(-3).join("/"))
            ) {
              resolvers = waiters;
              matchedUri = waitingUri;
              // Store diagnostics under the matched URI too
              this.diagnosticsMap.set(matchedUri, params.diagnostics);
              break;
            }
          }
        }

        if (resolvers && resolvers.length > 0) {
          this.waiters.delete(matchedUri);
          resolvers.forEach((r) => r());
        } else if (this.waiters.size > 0) {
          // Only flag as mismatch if we received a URI with the SAME filename
          // as one we're waiting for, but the full path differs.
          // Receiving diagnostics for unrelated files (e.g., tsconfig.json when
          // waiting for oracle.ts) is normal LSP behavior, not a mismatch.
          const incomingFilename = path.basename(fileUriToPath(params.uri));
          const waitingUris = [...this.waiters.keys()];
          const sameFilenameWaiters = waitingUris.filter(
            (uri) => path.basename(fileUriToPath(uri)) === incomingFilename,
          );

          if (sameFilenameWaiters.length > 0) {
            // This IS a mismatch: same filename but path didn't match
            this.lastMismatchInfo = `Received: ${params.uri}\nCanonical: ${canonicalUri}\nWaiting for: ${sameFilenameWaiters.join(", ")}`;
          }
          // Otherwise: just a different file, not a mismatch - don't overwrite lastMismatchInfo
        }
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

    const client = new PersistentLspClient(proc, connection, settings, onError);

    const defaultCapabilities = {
      textDocument: { publishDiagnostics: { relatedInformation: false } },
      workspace: {
        workspaceFolders: true,
        configuration: true,
      },
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

    // Push server-specific settings immediately after handshake (push model)
    // Note: Some servers like lua-language-server prefer the pull model
    // (workspace/configuration request) which is handled by the onRequest handler
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
   *
   * Key insight: We ALWAYS wait for publishDiagnostics after sending notifications.
   * The server should respond with diagnostics (even empty) for the file we touched.
   * If it doesn't respond within timeout, we return cached diagnostics.
   */
  async getDiagnostics(
    filePaths: string[],
    cwd: string,
    timeoutMs: number,
    signal?: AbortSignal,
  ): Promise<DiagnosticsResult> {
    const startTime = Date.now();

    // Resolve absolute paths and create both canonical and raw URIs
    // We'll try to match against both when receiving notifications
    const fileInfo = filePaths.map((f) => {
      const absPath = path.resolve(cwd, f);
      const canonicalUri = pathToCanonicalUri(absPath);
      const rawUri = pathToFileUri(absPath);
      return { absPath, canonicalUri, rawUri };
    });

    // Primary URIs we wait for (canonical)
    const uris = fileInfo.map((f) => f.canonicalUri);

    // Also register raw URIs as aliases for matching
    const rawUris = fileInfo.map((f) => f.rawUri);

    // Track pending URIs for debugging
    this.pendingUris = [...uris];
    this.lastMismatchInfo = null;

    // Track which URIs received responses
    const resolvedUris = new Set<string>();

    // Track notification count at start to detect ANY server activity
    const notifCountAtStart = this.totalNotificationsReceived;

    // Register waiters before sending notifications to avoid missing fast responses
    // Register for BOTH canonical and raw URIs to handle server differences
    const waiterPromises: Promise<void>[] = [];

    for (let i = 0; i < uris.length; i++) {
      const canonicalUri = uris[i]!;
      const rawUri = rawUris[i]!;

      const promise = new Promise<void>((resolve) => {
        const resolver = () => {
          resolvedUris.add(canonicalUri);
          resolve();
        };

        // Register under canonical URI
        const existingCanonical = this.waiters.get(canonicalUri) ?? [];
        existingCanonical.push(resolver);
        this.waiters.set(canonicalUri, existingCanonical);

        // Also register under raw URI if different (symlink case)
        if (rawUri !== canonicalUri) {
          const existingRaw = this.waiters.get(rawUri) ?? [];
          existingRaw.push(resolver);
          this.waiters.set(rawUri, existingRaw);
        }
      });

      waiterPromises.push(promise);
    }

    Promise.all(waiterPromises);

    // Send notifications for all files
    // Capture notification count AFTER sending to detect responses to OUR request
    const notifCountAfterSend = this.totalNotificationsReceived;
    const notifTimeAfterSend = this.lastNotificationTime;

    for (let i = 0; i < filePaths.length; i++) {
      const { absPath, canonicalUri } = fileInfo[i]!;
      const uri = canonicalUri;
      let text = "";
      try {
        text = fs.readFileSync(absPath, "utf8");
      } catch {
        /* let the LSP report the error */
      }

      if (!this.openedFiles.has(uri)) {
        // First open: send didOpen
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
        // Already open: send didChange + didSave and WAIT for response
        // Don't immediately resolve - we want fresh diagnostics
        const version = this.versionCounter++;
        this.connection.sendNotification("textDocument/didChange", {
          textDocument: { uri, version },
          contentChanges: [{ text }],
        });
        this.connection.sendNotification("textDocument/didSave", {
          textDocument: { uri },
          text,
        });
      }
    }

    // Race: all diagnostics arrive OR smart timeout OR abort
    //
    // Smart timeout logic:
    // - If server sends diagnostics for our file: resolve immediately
    // - If server is active (sending for other files) but silent for our file:
    //   wait for a "grace period" (500ms of silence) then assume file is clean
    // - Full timeout (3s) as fallback if server is completely silent
    const GRACE_PERIOD_MS = 500; // If server was active but silent for this long, assume clean
    const POLL_INTERVAL_MS = 100;

    let resolved = false;
    let timedOut = false;
    let abortedFlag = false;

    // Set up abort handler
    if (signal) {
      signal.addEventListener(
        "abort",
        () => {
          abortedFlag = true;
        },
        { once: true },
      );
    }

    // Poll-based waiting with grace period detection
    const waitStart = Date.now();

    while (!resolved && !timedOut && !abortedFlag) {
      // Check if all waiters have been resolved
      const allResolved = uris.every(
        (uri) => !this.waiters.has(uri) || resolvedUris.has(uri),
      );
      if (allResolved) {
        resolved = true;
        break;
      }

      // Check if we've exceeded the full timeout
      const elapsed = Date.now() - waitStart;
      if (elapsed >= timeoutMs) {
        timedOut = true;
        break;
      }

      // Smart early exit: if server has been active AFTER we sent didOpen
      // (sent notifications for other files) but hasn't sent anything for our file,
      // and there's been a grace period of silence, assume the file is clean
      const serverRespondedAfterOurRequest =
        this.totalNotificationsReceived > notifCountAfterSend;
      const lastNotifAge = Date.now() - this.lastNotificationTime;
      const serverSentSomethingAfterOurRequest =
        this.lastNotificationTime > notifTimeAfterSend;

      if (
        serverRespondedAfterOurRequest &&
        serverSentSomethingAfterOurRequest &&
        lastNotifAge >= GRACE_PERIOD_MS
      ) {
        // Server responded for other files but has been silent for grace period
        // This likely means our file is clean (no diagnostics to send)
        resolved = true; // Treat as resolved (file is clean)
        break;
      }

      // Also early exit if we've waited long enough after sending
      // In cold start scenarios with clean files, server may send nothing at all
      if (elapsed >= 1500) {
        // We've waited 1.5s - if no diagnostics for our file, assume clean
        resolved = true;
        break;
      }

      // Wait a bit before polling again
      await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
    }

    const receivedResponse = resolved && !timedOut;
    const durationMs = Date.now() - startTime;

    // Check if server sent ANY notifications (even for other files)
    const serverResponded = this.totalNotificationsReceived > notifCountAtStart;

    // Clear all waiters (both canonical and raw)
    for (const uri of uris) {
      this.waiters.delete(uri);
    }
    for (const uri of rawUris) {
      this.waiters.delete(uri);
    }

    // Build result from diagnosticsMap
    // Try both canonical and raw URIs when looking up
    const result = new Map<string, LspDiagnostic[]>();
    for (let i = 0; i < uris.length; i++) {
      const canonicalUri = uris[i]!;
      const rawUri = rawUris[i]!;

      // Try canonical first, then raw
      let diags = this.diagnosticsMap.get(canonicalUri);
      if (diags === undefined && rawUri !== canonicalUri) {
        diags = this.diagnosticsMap.get(rawUri);
      }
      result.set(canonicalUri, diags ?? []);
    }

    // Update timing metrics
    this.lastCheckDurationMs = durationMs;
    this.lastCheckReceivedResponse = receivedResponse;

    // Enhanced debug info
    if (!receivedResponse && serverResponded) {
      // Server sent something but not for our files - URI mismatch likely
      const lastReceived = this.receivedUris.slice(-3).join(", ");
      this.lastMismatchInfo = `Timeout but server active. Last received: ${lastReceived}\nWaiting for: ${uris.join(", ")}`;
    }

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
