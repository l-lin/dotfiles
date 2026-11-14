import * as path from "node:path";
import { loadUserRules, type UserRules } from "./settings.js";
import { AuditLog, type AuditRecord, type FallbackAudit } from "./audit.js";
import { anchorDenyPaths, classifyByRules } from "./rules.js";
import type { ProtectedSet } from "./protection.js";
import {
  classifyWithModel,
  FALLBACK_TIMEOUT_MS,
  MAX_ACTION_CHARS,
  toolCallLine,
  type ClassifierOutcome,
  type ClassifyFn,
  type CompletionFn,
  type PipelineHost,
  type ResolvedLayer,
} from "./classifier.js";

interface FallbackStats {
  triggered: number;
  agreed: number;
  overruled: number;
  errored: number;
  rescuedAllow: number;
}

class FallbackCascade {
  readonly stats: FallbackStats = {
    triggered: 0,
    agreed: 0,
    overruled: 0,
    errored: 0,
    rescuedAllow: 0,
  };

  reset(): void {
    Object.assign(this.stats, {
      triggered: 0,
      agreed: 0,
      overruled: 0,
      errored: 0,
      rescuedAllow: 0,
    });
  }

  note(
    first: "allow" | "ask" | "deny" | null,
    fallbackVerdict: "allow" | "ask" | "deny" | null,
  ): void {
    this.stats.triggered++;

    if (fallbackVerdict === null) {
      this.stats.errored++;

      return;
    }

    if (first === null && fallbackVerdict === "allow") {
      this.stats.rescuedAllow++;
    }

    if ((first ?? "deny") !== fallbackVerdict) {
      this.stats.overruled++;
    } else {
      this.stats.agreed++;
    }
  }

  summary(mode: "shadow" | "enforce"): string {
    const stats = this.stats;

    if (stats.triggered === 0) {
      return "confidence cascade: not triggered this session";
    }

    return `confidence cascade (${mode}): triggered ${stats.triggered} · agreed ${stats.agreed} · ${mode === "enforce" ? "overruled" : "would-overrule"} ${stats.overruled} · ${mode === "enforce" ? "rescued-allow" : "would-rescue-allow"} ${stats.rescuedAllow} · errored ${stats.errored}`;
  }
}

export class SessionState {
  readonly prot: ProtectedSet;
  readonly fallback = new FallbackCascade();
  userRules: UserRules;
  audit: AuditLog | null;
  private denyPathBases: string[] | null = null;
  private readonly agentDir: string | null;

  constructor(
    prot: ProtectedSet,
    userRules: UserRules = loadUserRules().rules,
    agentDir: string | null = null,
  ) {
    this.prot = prot;
    this.userRules = userRules;
    this.agentDir = agentDir;
    this.audit = this.makeAudit(userRules);
  }

  private makeAudit(rules: UserRules): AuditLog | null {
    return rules.audit && this.agentDir
      ? new AuditLog(
          path.join(this.agentDir, "verdicts"),
          rules.auditRedactSecrets,
        )
      : null;
  }

  reset(cwd: string): {
    skipped: string[];
  } {
    const loaded = loadUserRules();
    this.userRules = loaded.rules;
    this.denyPathBases = anchorDenyPaths(loaded.rules.denyPaths, cwd);
    this.fallback.reset();
    this.audit = this.makeAudit(loaded.rules);

    return { skipped: loaded.skipped };
  }

  anchoredDenyPathBases(cwd: string): string[] {
    if (this.denyPathBases === null) {
      this.denyPathBases = anchorDenyPaths(this.userRules.denyPaths, cwd);
    }

    return this.denyPathBases;
  }
}

export type VerdictSource =
  | "rule"
  | "protected-path"
  | "classifier"
  | "fail-closed";

export interface Verdict {
  verdict: "allow" | "ask" | "deny";
  reason: string;
  detail?: string;
  source: VerdictSource;
  degraded: boolean;
  pendingAudit?: AuditRecord;
}

export interface AdjudicateEnv {
  cwd: string;
  hasUI: boolean;
  getModel: () => ResolvedLayer | null;
  complete: CompletionFn;
  classify?: ClassifyFn;
  host: PipelineHost;
  signal?: AbortSignal;
  getFallbackModel?: () => ResolvedLayer | null;
}

function confidenceDemotion(
  outcome: ClassifierOutcome,
  rules: UserRules,
): {
  confidence: number;
} | null {
  if (
    rules.classifierMinConfidence === null ||
    outcome.source === "fail-closed" ||
    outcome.confidence === undefined
  ) {
    return null;
  }

  if (outcome.confidence < rules.classifierMinConfidence) {
    return { confidence: outcome.confidence };
  }

  return null;
}

interface CascadeResult {
  demoted?: true;
  fallbackAudit?: FallbackAudit;
  effective?: {
    verdict: "allow" | "ask" | "deny";
    reason: string;
    source: "classifier" | "fail-closed";
  };
}

async function runConfidenceCascade(
  state: SessionState,
  env: AdjudicateEnv,
  trigger:
    | {
        kind: "demotion";
        confidence: number;
        first: Pick<ClassifierOutcome, "verdict" | "reason">;
      }
    | {
        kind: "fail-closed";
      },
  denyPathsActive: boolean,
  actionLine: string,
): Promise<CascadeResult> {
  const rules = state.userRules;
  const first = trigger.kind === "demotion" ? trigger.first : null;
  const defaultDecision: CascadeResult =
    trigger.kind === "demotion"
      ? {
          demoted: true,
          effective: {
            verdict: "ask",
            reason: `${trigger.first.reason} (confidence ${trigger.confidence}% is below your classifierMinConfidence of ${rules.classifierMinConfidence}%)`,
            source: "classifier",
          },
        }
      : {};

  const getFallbackModel = env.getFallbackModel;

  if (!rules.classifierFallbackModel || !getFallbackModel) {
    return defaultDecision;
  }

  const mode = rules.classifierFallbackMode;
  const start = Date.now();
  const base = {
    mode,
    triggeredBy:
      trigger.kind === "demotion"
        ? ("confidence" as const)
        : ("fail-closed" as const),
    confidence: trigger.kind === "demotion" ? trigger.confidence : null,
  };
  const failed = (model: string, error: string): CascadeResult => {
    state.fallback.note(first?.verdict ?? null, null);
    const fallbackAudit: FallbackAudit = {
      ...base,
      model,
      verdict: null,
      reason: null,
      durationMs: Date.now() - start,
      error,
    };

    if (mode === "shadow") {
      return { ...defaultDecision, fallbackAudit };
    }

    return {
      ...defaultDecision,
      fallbackAudit: { ...fallbackAudit, effective: "ask" },
      effective: {
        verdict: "ask",
        reason:
          "fallback classifier unavailable (first layer abstained) — your call",
        source: "fail-closed",
      },
    };
  };
  const resolved = getFallbackModel();

  if (!resolved) {
    return failed(
      rules.classifierFallbackModel,
      "fallback model unresolvable (not found or no configured auth)",
    );
  }

  const outcome = await classifyWithModel(env, resolved, {
    actionLine,
    denyPathsActive,
    timeoutMs: FALLBACK_TIMEOUT_MS,
  });

  if (outcome.source !== "model") {
    return failed(resolved.model.id, outcome.reason);
  }

  state.fallback.note(first?.verdict ?? null, outcome.verdict);
  const fallbackAudit: FallbackAudit = {
    ...base,
    model: resolved.model.id,
    verdict: outcome.verdict,
    reason: outcome.reason,
    durationMs: Date.now() - start,
    error: null,
  };

  if (mode === "shadow") {
    return { ...defaultDecision, fallbackAudit };
  }

  // Keep human approval when the first classifier asks or denies, even if the fallback allows.
  if (
    trigger.kind === "demotion" &&
    (trigger.first.verdict === "deny" || trigger.first.verdict === "ask") &&
    outcome.verdict === "allow"
  ) {
    return {
      demoted: true,
      fallbackAudit: { ...fallbackAudit, effective: "ask" },
      effective: {
        verdict: "ask",
        reason: `${outcome.reason} (first layer said ${trigger.first.verdict} at confidence ${trigger.confidence}%; second opinion allows — your call)`,
        source: "classifier",
      },
    };
  }

  return {
    ...defaultDecision,
    fallbackAudit: { ...fallbackAudit, effective: outcome.verdict },
    effective: {
      verdict: outcome.verdict,
      reason: outcome.reason,
      source: "classifier",
    },
  };
}

export async function adjudicate(
  state: SessionState,
  call: {
    toolName: string;
    input: Record<string, unknown>;
    toolCallId?: string;
    parentToolCallId?: string;
  },
  env: AdjudicateEnv,
): Promise<Verdict> {
  const rule = classifyByRules(
    call.toolName,
    call.input,
    env.cwd,
    state.userRules,
    state.prot,
    state.anchoredDenyPathBases(env.cwd),
  );

  if (rule.verdict === "allow" || rule.verdict === "deny") {
    return {
      verdict: rule.verdict,
      reason: rule.reason ?? "",
      source: "rule",
      degraded: false,
    };
  }

  const actionLine = toolCallLine(call.toolName, call.input, MAX_ACTION_CHARS);
  const buildRecord = (
    decision: Pick<AuditRecord, "verdict" | "reason" | "source" | "degraded">,
    raw: ClassifierOutcome["auditRaw"] | null,
  ): AuditRecord => ({
    ts: new Date().toISOString(),
    sessionId: env.host.getSessionId(),
    cwd: env.cwd,
    model: raw?.modelId ?? null,
    tool: call.toolName,
    input: call.input,
    actionLine,
    thinking: raw?.thinking ?? null,
    transcript: raw?.transcript ?? null,
    rawResponse: raw?.rawResponse ?? null,
    ...(call.toolCallId !== undefined ? { toolCallId: call.toolCallId } : {}),
    ...(call.parentToolCallId !== undefined
      ? { parentToolCallId: call.parentToolCallId }
      : {}),
    ...decision,
  });

  if (rule.verdict === "ask") {
    const decision: Verdict = {
      verdict: env.hasUI ? "ask" : "deny",
      reason: rule.reason ?? "",
      detail: rule.detail,
      source: "protected-path",
      degraded: !env.hasUI,
    };
    const record: AuditRecord = {
      ...buildRecord({ ...decision, source: "protected-path" }, null),
      detail: rule.detail,
    };

    if (env.hasUI) {
      if (state.audit) {
        decision.pendingAudit = record;
      }
    } else {
      state.audit?.append(record);
    }

    return decision;
  }

  if (
    call.parentToolCallId !== undefined &&
    state.userRules.codemodeNestedCalls === "rules-only"
  ) {
    const reason =
      "codemodeNestedCalls rules-only: gray-zone passthrough (nested call — deterministic layers only)";
    state.audit?.append({
      ...buildRecord(
        { verdict: "allow", reason, source: "rule", degraded: false },
        null,
      ),
      policy: "rules-only",
    });

    return { verdict: "allow", reason, source: "rule", degraded: false };
  }

  const resolved = env.getModel();

  if (!resolved) {
    const reason = "no classifier model available (fail-closed)";
    const cascade = await runConfidenceCascade(
      state,
      env,
      { kind: "fail-closed" },
      state.userRules.denyPaths.length > 0,
      actionLine,
    );
    const effective = cascade.effective;
    const askWithoutUI = effective?.verdict === "ask" && !env.hasUI;
    const failureRecord = buildRecord(
      {
        verdict: askWithoutUI ? "deny" : (effective?.verdict ?? "deny"),
        reason: effective?.reason ?? reason,
        source: "fail-closed",
        degraded: askWithoutUI,
      },
      null,
    );

    if (cascade.fallbackAudit) {
      failureRecord.fallback = cascade.fallbackAudit;
    }

    if (effective?.verdict === "ask" && env.hasUI) {
      return {
        verdict: "ask",
        reason: effective.reason,
        source: effective.source,
        degraded: false,
        ...(state.audit ? { pendingAudit: failureRecord } : {}),
      };
    }

    state.audit?.append(failureRecord);

    if (effective?.verdict === "allow") {
      return {
        verdict: "allow",
        reason: effective.reason,
        source: "classifier",
        degraded: false,
      };
    }

    if (effective) {
      return {
        verdict: "deny",
        reason: effective.reason,
        source: effective.source,
        degraded: askWithoutUI,
      };
    }

    return { verdict: "deny", reason, source: "fail-closed", degraded: false };
  }

  const outcome = await classifyWithModel(env, resolved, {
    actionLine,
    denyPathsActive: state.userRules.denyPaths.length > 0,
  });
  const demotion = confidenceDemotion(outcome, state.userRules);
  const cascade =
    demotion || outcome.source === "fail-closed"
      ? await runConfidenceCascade(
          state,
          env,
          demotion
            ? {
                kind: "demotion",
                confidence: demotion.confidence,
                first: { verdict: outcome.verdict, reason: outcome.reason },
              }
            : { kind: "fail-closed" },
          state.userRules.denyPaths.length > 0,
          actionLine,
        )
      : {};
  const effectiveVerdict = cascade.effective?.verdict ?? outcome.verdict;
  const effectiveReason = cascade.effective?.reason ?? outcome.reason;
  const effectiveSource = cascade.effective?.source ?? "classifier";
  const appliedAskHeadless = !env.hasUI && effectiveVerdict === "ask";
  const failureRescued =
    cascade.effective !== undefined && outcome.source === "fail-closed";
  const classifierRecord = buildRecord(
    {
      verdict: appliedAskHeadless
        ? "deny"
        : failureRescued
          ? effectiveVerdict
          : outcome.verdict,
      reason: failureRescued ? effectiveReason : outcome.reason,
      source: outcome.source,
      degraded: appliedAskHeadless,
    },
    outcome.auditRaw ?? null,
  );

  if (cascade.demoted) {
    classifierRecord.demoted = true;
  }

  if (cascade.fallbackAudit) {
    classifierRecord.fallback = cascade.fallbackAudit;
  }

  if (effectiveVerdict === "ask" && env.hasUI) {
    return {
      verdict: "ask",
      reason: effectiveReason,
      source: effectiveSource,
      degraded: false,
      ...(state.audit ? { pendingAudit: classifierRecord } : {}),
    };
  }

  state.audit?.append(classifierRecord);

  return {
    verdict: appliedAskHeadless ? "deny" : effectiveVerdict,
    reason: effectiveReason,
    source: effectiveSource,
    degraded: appliedAskHeadless,
  };
}
