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
        this.diagnosticsMap.set(params.uri, params.diagnostics);
        const resolvers = this.waiters.get(params.uri) ?? [];
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
  ): Promise<PersistentLspClient> {
    const projectRoot = rootDir ?? cwd;
    const [cmd, ...args] = lspCommand;
    const proc = spawn(cmd!, args, { cwd: projectRoot, stdio: ["pipe", "pipe", "pipe"] });

    // Silently swallow writes to a destroyed stdin (vscode-jsonrpc flushes async)
    if (proc.stdin) {
      const _origWrite = proc.stdin.write.bind(proc.stdin);
      (proc.stdin as any).write = (chunk: any, encodingOrCb?: any, cb?: any): boolean => {
        if (proc.stdin!.destroyed) {
          const callback = typeof encodingOrCb === "function" ? encodingOrCb : cb;
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

    await Promise.race([
      spawnError,
      connection.sendRequest("initialize", {
        processId: process.pid,
        rootUri: pathToFileUri(projectRoot),
        capabilities: {
          textDocument: { publishDiagnostics: { relatedInformation: false } },
          workspace: { workspaceFolders: true },
        },
        workspaceFolders: [{ uri: pathToFileUri(projectRoot), name: path.basename(projectRoot) }],
      }),
    ]);

    connection.sendNotification("initialized", {});

    // Push server-specific settings immediately after handshake
    if (settings && Object.keys(settings).length > 0) {
      connection.sendNotification("workspace/didChangeConfiguration", {
        settings,
      });
    }

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
  ): Promise<Map<string, LspDiagnostic[]>> {
    const uris = filePaths.map((f) => pathToFileUri(path.resolve(cwd, f)));

    // Register waiters before sending notifications to avoid missing fast responses
    const diagnosticsReady = Promise.all(
      uris.map(
        (uri) =>
          new Promise<void>((resolve) => {
            const existing = this.waiters.get(uri) ?? [];
            existing.push(resolve);
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

    // Race: all diagnostics arrive OR timeout OR abort
    const timeout = new Promise<void>((resolve) => setTimeout(resolve, timeoutMs));
    const aborted = signal
      ? new Promise<void>((resolve) => signal.addEventListener("abort", () => resolve(), { once: true }))
      : null;
    await Promise.race([diagnosticsReady, timeout, ...(aborted ? [aborted] : [])]);

    // Clear any stale waiters that timed out
    for (const uri of uris) {
      this.waiters.delete(uri);
    }

    const result = new Map<string, LspDiagnostic[]>();
    for (const uri of uris) {
      result.set(uri, this.diagnosticsMap.get(uri) ?? []);
    }
    return result;
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
