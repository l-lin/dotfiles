import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { isDeepStrictEqual } from "node:util";
import {
  baseForms,
  rebuiltForms,
  expandHome,
  pathStartsWith,
} from "./paths.js";
import type { RuleResult } from "./rules.js";
import {
  settingsPreserveVerdict,
  snapshotVerdictSection,
  restoreVerdictSection,
} from "./settings.js";

export type WatchKind = "config" | "extension";

export interface ProtectedSet {
  exact: string[];
  prefixes: string[];
  readPrefixes: string[];
  bashPatterns: RegExp[];
  watchBases: Array<{ file: string; kind: WatchKind }>;
  settingsFile: string;
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

export function buildProtectedSet(
  agentDir: string,
  ownFile: string | null,
): ProtectedSet {
  const settingsFile = path.join(agentDir, "settings.json");
  const exact = new Set(baseForms(settingsFile));
  const prefixes = new Set<string>();
  const watchBases: ProtectedSet["watchBases"] = [
    { file: settingsFile, kind: "config" },
  ];
  const targets = new Set<string>();
  const extensionRoots = baseForms(path.join(agentDir, "extensions"));

  function addWatchedFiles(file: string, depth: number): void {
    if (depth > 16 || watchBases.length >= 500) {
      return;
    }

    try {
      if (!fs.statSync(file).isDirectory()) {
        watchBases.push({ file, kind: "extension" });

        return;
      }

      for (const name of fs.readdirSync(file)) {
        if (name !== "node_modules" && name !== ".git") {
          addWatchedFiles(path.join(file, name), depth + 1);
        }
      }
    } catch {
      // Keep unreadable files in the baseline so later changes remain visible.
      watchBases.push({ file, kind: "extension" });
    }
  }

  if (ownFile) {
    for (const root of extensionRoots) {
      for (const own of baseForms(ownFile)) {
        if (!own.startsWith(root + path.sep)) {
          continue;
        }

        const segments = path.relative(root, own).split(path.sep);
        const target =
          segments.length === 1 ? own : path.join(root, segments[0]);
        targets.add(target);

        if (segments.length === 1) {
          exact.add(target);
        } else {
          for (const form of baseForms(target)) {
            prefixes.add(form);
          }
        }

        addWatchedFiles(target, 0);
        // The shared settings helper can change gate settings without a tool call.
        const helper = path.join(root, "tool-settings", "index.ts");

        if (fs.existsSync(helper)) {
          for (const form of baseForms(helper)) {
            exact.add(form);
          }

          targets.add(helper);
          watchBases.push({ file: helper, kind: "extension" });
        }
      }
    }
  }

  const readPrefixes = baseForms(path.join(agentDir, "verdicts"));

  for (const form of readPrefixes) {
    prefixes.add(form);
  }

  const spellings = new Set<string>();

  for (const file of [settingsFile, ...targets, ...readPrefixes]) {
    for (const form of baseForms(file)) {
      spellings.add(escapeRegExp(form));
      const home = os.homedir();

      if (form.startsWith(home + path.sep)) {
        const relative = form.slice(home.length + 1);
        spellings.add(escapeRegExp("~/" + relative));
        spellings.add("\\$HOME/" + escapeRegExp(relative));
      }
    }
  }

  return {
    settingsFile,
    exact: [...exact],
    prefixes: [...prefixes],
    readPrefixes,
    bashPatterns: [new RegExp(`(?:${[...spellings].join("|")})`)],
    watchBases,
  };
}

export function isSettingsPath(
  rawPath: string,
  cwd: string,
  prot: ProtectedSet,
): boolean {
  const bases = rebuiltForms(prot.settingsFile);

  return rebuiltForms(path.resolve(cwd, expandHome(rawPath))).some((form) =>
    bases.includes(form),
  );
}

export function isProtectedWritePath(
  rawPath: string,
  cwd: string,
  prot: ProtectedSet,
): boolean {
  if (!rawPath) {
    return false;
  }

  return rebuiltForms(path.resolve(cwd, expandHome(rawPath))).some(
    (form) =>
      prot.exact.includes(form) ||
      prot.prefixes.some(
        (prefix) => form === prefix || form.startsWith(prefix + path.sep),
      ),
  );
}

export function isProtectedReadPath(
  rawPath: string | undefined,
  cwd: string,
  prot: ProtectedSet,
  subtree = false,
): boolean {
  return rebuiltForms(path.resolve(cwd, expandHome(rawPath ?? cwd))).some(
    (form) =>
      prot.readPrefixes.some(
        (prefix) =>
          form === prefix ||
          form.startsWith(prefix + path.sep) ||
          (subtree && pathStartsWith(prefix, form)),
      ),
  );
}

function proposedSettings(
  toolName: string,
  input: Record<string, unknown>,
  current: string,
): string | null {
  if (toolName === "write") {
    return typeof input.content === "string" ? input.content : null;
  }

  if (!Array.isArray(input.edits) || input.edits.length === 0) {
    return null;
  }

  const changes: Array<{ start: number; end: number; text: string }> = [];

  for (const edit of input.edits) {
    if (
      !edit ||
      typeof edit.oldText !== "string" ||
      !edit.oldText ||
      typeof edit.newText !== "string"
    ) {
      return null;
    }

    const start = current.indexOf(edit.oldText);

    if (start < 0 || current.indexOf(edit.oldText, start + 1) >= 0) {
      return null;
    }

    changes.push({
      start,
      end: start + edit.oldText.length,
      text: edit.newText,
    });
  }

  changes.sort((a, b) => b.start - a.start);
  let proposed = current;
  let boundary = current.length;

  for (const change of changes) {
    if (change.end > boundary) {
      return null;
    }

    proposed =
      proposed.slice(0, change.start) +
      change.text +
      proposed.slice(change.end);
    boundary = change.start;
  }

  return proposed;
}

export function selfProtectCheck(
  toolName: string,
  input: Record<string, unknown>,
  cwd: string,
  prot: ProtectedSet,
): RuleResult | null {
  const deny = (reason: string): RuleResult => ({
    verdict: "deny",
    reason: `self-protection: ${reason}`,
  });
  const rawPath = typeof input.path === "string" ? input.path : "";

  if (toolName === "write" || toolName === "edit") {
    if (rawPath && isSettingsPath(rawPath, cwd, prot)) {
      try {
        const current = fs.existsSync(prot.settingsFile)
          ? fs.readFileSync(prot.settingsFile, "utf8")
          : "{}";
        const proposed = proposedSettings(toolName, input, current);

        if (proposed !== null && settingsPreserveVerdict(current, proposed)) {
          return null;
        }
      } catch {
        // Unknown settings changes must not weaken the gate.
      }

      return deny(
        "agent changes to extensionSettings.verdict are blocked; edit this section outside Pi",
      );
    }

    return isProtectedWritePath(rawPath, cwd, prot)
      ? deny("agent changes to verdict code or audit files are blocked")
      : null;
  }

  if (["read", "grep", "find", "ls"].includes(toolName)) {
    const subtree = toolName !== "read";

    return isProtectedReadPath(rawPath || undefined, cwd, prot, subtree)
      ? deny("agent reads of audit files are blocked; view them outside Pi")
      : null;
  }

  if (toolName === "bash" || toolName === "powershell") {
    const command = String(input.command ?? "");
    const settingsTokens = /(?:^|[\s'"/])settings\.json(?:[\s'";]|$)/.test(
      command,
    );

    return settingsTokens ||
      prot.bashPatterns.some((pattern) => pattern.test(command))
      ? deny(
          "command touches settings or verdict files; use direct file tools for sibling settings",
        )
      : null;
  }

  for (const value of Object.values(input)) {
    if (typeof value !== "string") {
      continue;
    }

    if (
      isProtectedReadPath(value, cwd, prot) ||
      isProtectedWritePath(value, cwd, prot)
    ) {
      return deny("custom tool input names a protected path");
    }
  }

  return null;
}

type Snapshot = { file: string; kind: WatchKind; content: Buffer | null };

function readSnapshot(file: string, kind: WatchKind): Buffer | null {
  if (kind === "config") {
    return snapshotVerdictSection(file);
  }

  try {
    return fs.readFileSync(file);
  } catch {
    return null;
  }
}

export class IntegrityWatch {
  private snapshots: Snapshot[] = [];
  private _tampered = false;

  constructor(private readonly watchBases: ProtectedSet["watchBases"]) {
    this.rebaseline();
  }

  get tampered(): boolean {
    return this._tampered;
  }

  detect(): Array<{ file: string; kind: WatchKind }> {
    return this.snapshots
      .filter((snapshot) => {
        const current = readSnapshot(snapshot.file, snapshot.kind);

        if (snapshot.kind === "config" && current && snapshot.content) {
          return !isDeepStrictEqual(
            JSON.parse(current.toString()),
            JSON.parse(snapshot.content.toString()),
          );
        }

        return current === null || snapshot.content === null
          ? current !== snapshot.content
          : !current.equals(snapshot.content);
      })
      .map(({ file, kind }) => ({ file, kind }));
  }

  rebaseline(): void {
    const seen = new Set<string>();
    this.snapshots = this.watchBases.flatMap(({ file, kind }) =>
      baseForms(file).flatMap((form) => {
        if (seen.has(form)) {
          return [];
        }

        seen.add(form);

        return [{ file: form, kind, content: readSnapshot(form, kind) }];
      }),
    );
  }

  refreshSettingsBaseline(): void {
    for (const snapshot of this.snapshots) {
      if (snapshot.kind === "config") {
        snapshot.content = readSnapshot(snapshot.file, snapshot.kind);
      }
    }
  }

  startSession(): void {
    this.rebaseline();
    this._tampered = false;
  }

  restoreAndFailClose(
    changed: Array<{ file: string }>,
    cause: string,
  ): { reason: string; files: string } {
    const failed: string[] = [];

    for (const { file } of changed) {
      const snapshot = this.snapshots.find((entry) => entry.file === file);

      if (!snapshot) {
        continue;
      }

      try {
        if (snapshot.kind === "config" && snapshot.content) {
          restoreVerdictSection(file, snapshot.content);
        } else if (snapshot.content) {
          fs.writeFileSync(file, snapshot.content);
        } else {
          fs.rmSync(file, { force: true });
        }
      } catch {
        failed.push(file);
      }
    }

    this._tampered = true;
    const files = [...new Set(changed.map(({ file }) => file))].join(", ");

    return {
      files,
      reason: `Tamper detected (${cause || "protected files changed"}); blocked until restart.${failed.length ? ` Restore failed: ${failed.join(", ")}.` : ""}`,
    };
  }
}
