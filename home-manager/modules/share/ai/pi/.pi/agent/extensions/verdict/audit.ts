import * as crypto from "node:crypto";
import * as fs from "node:fs";
import * as path from "node:path";

const AUDIT_KEEP_SESSIONS = 20;

export interface FallbackAudit {
  model: string;
  mode: "shadow" | "enforce";
  triggeredBy: "confidence" | "fail-closed";
  confidence: number | null;
  verdict: "allow" | "ask" | "deny" | null;
  reason: string | null;
  durationMs: number;
  error: string | null;
  effective?: "allow" | "ask" | "deny";
}

export interface AuditRecord {
  ts: string;
  sessionId: string;
  cwd: string;
  model: string | null;
  tool: string;
  input: unknown;
  actionLine: string;
  thinking: string | null;
  transcript: string | null;
  rawResponse: string | null;
  verdict: "allow" | "ask" | "deny";
  reason: string;
  source: "model" | "fail-closed" | "protected-path" | "rule";
  degraded: boolean;
  userAnswer?: "allowed" | "declined";
  answeredAt?: string;
  toolCallId?: string;
  parentToolCallId?: string;
  policy?: "rules-only";
  detail?: string;
  demoted?: true;
  fallback?: FallbackAudit;
}

function redactionFingerprint(secret: string): string {
  return crypto.createHash("sha256").update(secret).digest("hex").slice(0, 8);
}

const REDACT_CONTEXT_RULES: ReadonlyArray<{
  re: RegExp;
  build: (...m: string[]) => string;
}> = [
  {
    re: /(https?:\/\/[^/\s:@]+:)([^@/\s<]{8,})(?=@)/g,
    build: (...m) => `${m[1]}<redacted:url#${redactionFingerprint(m[2])}>`,
  },
  {
    re: /(-u\s+"?)([^:\s"<]+):([^"\s<]{8,})(")/g,
    build: (...m) =>
      `${m[1]}${m[2]}:<redacted:basic#${redactionFingerprint(m[3])}>${m[4]}`,
  },
  {
    re: /(-u\s+)([^:\s"<]+):([^"\s<]{8,})/g,
    build: (...m) =>
      `${m[1]}${m[2]}:<redacted:basic#${redactionFingerprint(m[3])}>`,
  },
  {
    re: /([?&](?:token|apikey|api_key|access_token|client_secret|signature|sig)=)([^&\s"'#<>]{8,})/gi,
    build: (...m) => `${m[1]}<redacted:query#${redactionFingerprint(m[2])}>`,
  },
  {
    re: /\b([A-Za-z_][A-Za-z0-9_]*(?:_KEY|_TOKEN|_SECRET|_PASSWORD|_CREDENTIALS?)|APIKEY|TOKEN|SECRET)(=)("[^"<]{8,}"|[^\s"<&;]{8,})/gi,
    build: (...m) =>
      `${m[1]}${m[2]}<redacted:env#${redactionFingerprint(m[3].replace(/^"|"$/g, ""))}>`,
  },
  {
    re: /(\bbearer\s+)([A-Za-z0-9._~+/=-]{8,})/gi,
    build: (...m) => `${m[1]}<redacted:bearer#${redactionFingerprint(m[2])}>`,
  },
];

const REDACT_TOKEN_SHAPES: ReadonlyArray<{
  type: string;
  re: RegExp;
}> = [
  {
    type: "jwt",
    re: /eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{4,}/g,
  },
  { type: "github_pat", re: /github_pat_[A-Za-z0-9_]{22,}/g },
  { type: "gh", re: /gh[posur]_[A-Za-z0-9]{30,}/g },
  { type: "sk-ant", re: /sk-ant-[A-Za-z0-9_-]{20,}/g },
  { type: "sk", re: /sk-[A-Za-z0-9][A-Za-z0-9_-]{15,}/g },
  { type: "pk", re: /pk-[A-Za-z0-9][A-Za-z0-9_-]{15,}/g },
  { type: "aws", re: /AKIA[0-9A-Z]{16}/g },
  { type: "slack", re: /xox[abprs]-[A-Za-z0-9-]{10,}/g },
  { type: "google", re: /AIza[0-9A-Za-z_-]{30,}/g },
];

function redactString(value: string): string {
  let redacted = value;

  for (const { re, build } of REDACT_CONTEXT_RULES) {
    redacted = redacted.replace(re, build);
  }

  for (const { type, re } of REDACT_TOKEN_SHAPES) {
    redacted = redacted.replace(
      re,
      (m) => `<redacted:${type}#${redactionFingerprint(m)}>`,
    );
  }

  return redacted;
}

export function redactSecrets<T>(value: T): T {
  if (typeof value === "string") {
    return redactString(value) as T;
  }

  if (Array.isArray(value)) {
    return value.map((entry) => redactSecrets(entry)) as T;
  }

  if (value !== null && typeof value === "object") {
    const prototype = Object.getPrototypeOf(value);

    if (prototype !== Object.prototype && prototype !== null) {
      return value;
    }

    const redacted: Record<string, unknown> = {};

    for (const [key, entry] of Object.entries(
      value as Record<string, unknown>,
    )) {
      redacted[key] = redactSecrets(entry);
    }

    return redacted as T;
  }

  return value;
}

export class AuditLog {
  private warning: string | null = null;
  private warned = false;

  constructor(
    readonly dir: string,
    readonly redact = true,
  ) {}

  append(record: AuditRecord): void {
    const file = path.join(
      this.dir,
      `${record.sessionId.replace(/[^a-zA-Z0-9_-]/g, "_")}.jsonl`,
    );

    try {
      fs.mkdirSync(this.dir, { recursive: true });
      let persisted: AuditRecord = record;

      if (this.redact) {
        try {
          persisted = redactSecrets(record);
        } catch {
          try {
            // Serialization can handle deeper records than the recursive redactor.
            persisted = JSON.parse(
              redactString(JSON.stringify(record)),
            ) as AuditRecord;
          } catch {}
        }
      }

      fs.appendFileSync(file, JSON.stringify(persisted) + "\n");
    } catch (error) {
      if (!this.warned) {
        this.warned = true;
        this.warning = `audit log write failed (${error instanceof Error ? error.message : String(error)}) — verdict records are NOT being persisted to ${this.dir}; adjudication is unaffected`;
      }
    }
  }

  drainWarning(): string | null {
    const warning = this.warning;
    this.warning = null;

    return warning;
  }

  prune(): void {
    let files: string[];

    try {
      files = fs
        .readdirSync(this.dir)
        .filter((file) => file.endsWith(".jsonl"));
    } catch {
      return;
    }

    if (files.length <= AUDIT_KEEP_SESSIONS) {
      return;
    }

    const newestFirst = files
      .map((file) => {
        let modifiedAt = 0;

        try {
          modifiedAt = fs.statSync(path.join(this.dir, file)).mtimeMs;
        } catch {}

        return { file, modifiedAt };
      })
      .sort((left, right) => right.modifiedAt - left.modifiedAt);

    for (const { file } of newestFirst.slice(AUDIT_KEEP_SESSIONS)) {
      try {
        fs.unlinkSync(path.join(this.dir, file));
      } catch {}
    }
  }
}
