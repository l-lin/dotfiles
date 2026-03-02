/**
 * LSP server lifecycle: initialize → open files → collect diagnostics → shutdown.
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

export async function collectDiagnostics(
  lspCommand: string[],
  filePaths: string[],
  cwd: string,
  timeoutMs: number,
  signal?: AbortSignal,
  onError?: (msg: string, severity?: "info" | "warning" | "error") => void,
): Promise<Map<string, LspDiagnostic[]>> {
  const [cmd, ...args] = lspCommand;
  const proc = spawn(cmd!, args, { cwd, stdio: ["pipe", "pipe", "pipe"] });

  // Monkey-patch proc.stdin.write so writes to a destroyed stream silently
  // succeed instead of rejecting. vscode-jsonrpc queues writes via setImmediate;
  // by the time they fire the stream may already be destroyed after LSP shutdown.
  if (proc.stdin) {
    const _origWrite = proc.stdin.write.bind(proc.stdin);
    (proc.stdin as any).write = (
      chunk: any,
      encodingOrCb?: any,
      cb?: any,
    ): boolean => {
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

  // Reject immediately if the binary isn't found; .catch() suppresses the
  // unhandled rejection if initialize() wins the race first.
  const spawnError = new Promise<never>((_, reject) => {
    proc.on("error", (err) => reject(err));
  }).catch(() => {}) as Promise<never>;

  const connection = createMessageConnection(
    new StreamMessageReader(proc.stdout!),
    new StreamMessageWriter(proc.stdin!),
  );
  connection.listen();

  const allDiagnostics = new Map<string, LspDiagnostic[]>(
    filePaths.map((f) => [pathToFileUri(path.resolve(cwd, f)), []]),
  );
  const received = new Set<string>();

  connection.onNotification(
    "textDocument/publishDiagnostics",
    (params: PublishDiagnosticsParams) => {
      if (allDiagnostics.has(params.uri)) {
        allDiagnostics.set(params.uri, params.diagnostics);
        received.add(params.uri);
      }
    },
  );

  try {
    await Promise.race([
      spawnError,
      connection.sendRequest("initialize", {
        processId: process.pid,
        rootUri: pathToFileUri(cwd),
        capabilities: {
          textDocument: { publishDiagnostics: { relatedInformation: false } },
          workspace: { workspaceFolders: true },
        },
        workspaceFolders: [
          { uri: pathToFileUri(cwd), name: path.basename(cwd) },
        ],
      }),
    ]);

    connection.sendNotification("initialized", {});

    for (const filePath of filePaths) {
      const absPath = path.resolve(cwd, filePath);
      let text = "";
      try {
        text = fs.readFileSync(absPath, "utf8");
      } catch {
        /* LSP will error */
      }

      connection.sendNotification("textDocument/didOpen", {
        textDocument: {
          uri: pathToFileUri(absPath),
          languageId: guessLanguageId(absPath),
          version: 1,
          text,
        },
      });
    }

    // Wait for all diagnostics or timeout, whichever comes first
    const allUris = [...allDiagnostics.keys()];
    await new Promise<void>((resolve) => {
      const timer = setTimeout(resolve, timeoutMs);
      const interval = setInterval(() => {
        if (allUris.every((u) => received.has(u))) {
          clearInterval(interval);
          clearTimeout(timer);
          resolve();
        }
      }, 200);
      signal?.addEventListener(
        "abort",
        () => {
          clearInterval(interval);
          clearTimeout(timer);
          resolve();
        },
        { once: true },
      );
    });

    try {
      let shutdownTimer: ReturnType<typeof setTimeout> | undefined;
      await Promise.race([
        connection.sendRequest("shutdown", null),
        new Promise((_, reject) => {
          shutdownTimer = setTimeout(
            () => reject(new Error("shutdown timeout")),
            3000,
          );
        }),
      ]).finally(() => clearTimeout(shutdownTimer));
      if (!proc.stdin?.destroyed) connection.sendNotification("exit", {});
    } catch {
      /* ignore shutdown errors */
    }
  } finally {
    connection.dispose();
    proc.kill();
  }

  return allDiagnostics;
}
