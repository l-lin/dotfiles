import { fileURLToPath } from "node:url";
import { classify } from "@earendil-works/pi-ai/api/typesafe-system-one";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { registerExtensionToggleCommand } from "../tool-settings/index.js";
import {
  agentDirPath,
  DEFAULT_CLASSIFIER,
  EXTENSION_KEY,
  loadUserRules,
  saveEnabled,
} from "./settings.js";
import {
  IntegrityWatch,
  buildProtectedSet,
  type WatchKind,
} from "./protection.js";
import { adjudicate, SessionState, type Verdict } from "./pipeline.js";
import {
  MAX_ACTION_CHARS,
  toolCallLine,
  resolveModelSpec,
  parseModelSpec,
  type ResolvedLayer,
} from "./classifier.js";

export function blockedReason(tag: string, detail: string): string {
  const reason = detail.trim().replace(/\.+$/, "") || "No reason was provided";

  return `[verdict ${tag} block] BLOCKED. This action did not run. Reason: ${reason}. Report the block. Do not report success.`;
}

const DECISION_ICONS = {
  allow: "",
  confidence: "",
  ask: "󰋗",
  deny: "󰅙",
} as const;

export function debugMessage(value: Verdict, action: string): string {
  const reason = value.reason.replace(
    /(?:jev|classifier): ((?:allow|ask|deny) \d+% \(confidence \d+%; [^)]+\))/g,
    (_match, scores: string) =>
      scores
        .replace(
          /\b(allow|ask|deny|confidence)\b/g,
          (label) => DECISION_ICONS[label as keyof typeof DECISION_ICONS],
        )
        .replace(/[;,]/g, ""),
  );
  const result =
    reason === value.reason
      ? `${DECISION_ICONS[value.verdict]} (${value.source}): ${reason}`
      : reason;
  // Protected paths appear only in the approval dialog.
  const tool =
    value.source === "protected-path"
      ? `${action.split(":", 1)[0]}: [protected path]`
      : action;

  const preview = tool.length > 200 ? `${tool.slice(0, 199)}…` : tool;

  return ` ${preview}\n ${result}`;
}

export default function verdict(pi: ExtensionAPI): void {
  pi.registerProvider("verdict-local", {
    name: "Verdict local Kev",
    baseUrl: "http://127.0.0.1:11436/v1",
    apiKey: "local",
    models: [
      {
        type: "classifier",
        id: "kev",
        name: "Kev",
        api: "typesafe-system-one",
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 32768,
      },
    ],
    classifiers: { "typesafe-system-one": { classify } },
  });
  const control = { enabled: true };
  const state = new SessionState(
    buildProtectedSet(agentDirPath(), fileURLToPath(import.meta.url)),
    undefined,
    agentDirPath(),
  );
  const integrity = new IntegrityWatch(state.prot.watchBases);
  const warned = new Set<string>();
  let started = false;
  const debug = () => state.userRules.debug;
  const publishStatus = () =>
    pi.events.emit("verdict:changed", { enabled: control.enabled });
  pi.events.on("verdict:request-status", () => {
    if (started) {
      publishStatus();
    }
  });
  pi.on("session_shutdown", () => {
    started = false;
    pi.events.emit("verdict:changed", { enabled: undefined });
  });

  function warnOnce(ctx: ExtensionContext, key: string, message: string): void {
    if (warned.has(key)) {
      return;
    }

    warned.add(key);
    ctx.ui.notify(`verdict: ${message}`, "warning");
  }

  function primarySpec(): string {
    return (
      process.env.PI_AUTO_MODE_MODEL ??
      state.userRules.classifierModel ??
      DEFAULT_CLASSIFIER
    );
  }

  function resolveClassifier(
    ctx: ExtensionContext,
    fallback = false,
  ): ResolvedLayer | null {
    const raw = fallback
      ? state.userRules.classifierFallbackModel
      : primarySpec();

    if (raw === null) {
      return null;
    }

    const layer = fallback ? "fallback" : "classifier";
    const resolved = raw
      ? resolveModelSpec(ctx, raw, (message) =>
          warnOnce(ctx, `${layer}:${message}`, message),
        )
      : null;

    if (resolved) {
      if (
        !fallback &&
        resolved.kind === "chat" &&
        state.userRules.classifierMinConfidence !== null
      ) {
        warnOnce(
          ctx,
          "confidence",
          "classifierMinConfidence has no effect on a chat model",
        );
      }

      return resolved;
    }

    warnOnce(
      ctx,
      `${layer}:unavailable`,
      `${layer} model ${JSON.stringify(raw)} is unavailable.${fallback ? " The fallback is inactive." : " Verdict will use the session model."}`,
    );

    if (fallback || !ctx.model) {
      return null;
    }

    if (state.userRules.classifierMinConfidence !== null) {
      warnOnce(
        ctx,
        "confidence",
        "classifierMinConfidence has no effect on a chat model",
      );
    }

    return {
      kind: "chat",
      model: ctx.model,
      thinking: parseModelSpec(raw, () => {}).thinking,
    };
  }

  pi.on("session_start", (_event, ctx) => {
    const report = state.reset(ctx.cwd);
    control.enabled = loadUserRules().enabled;
    warned.clear();
    integrity.startSession();
    state.audit?.prune();
    started = true;

    if (report.skipped.length) {
      ctx.ui.notify(
        `verdict: skipped invalid settings: ${report.skipped.join(", ")}`,
        "warning",
      );
    }

    publishStatus();
  });

  registerExtensionToggleCommand(pi, {
    commandName: "cmd:verdict-toggle",
    description: "Enable or disable verdict permission checks",
    label: EXTENSION_KEY,
    settings: control,
    saveEnabled(enabled) {
      saveEnabled(enabled);
      integrity.refreshSettingsBaseline();
    },
    applyEnabledState() {
      publishStatus();
    },
  });
  pi.registerCommand("cmd:verdict-status", {
    description: "Show verdict settings and session status",
    handler: async (_args, ctx) => {
      const rules = state.userRules;
      const details = [
        `verdict: ${control.enabled ? "enabled" : "disabled"}`,
        `classifier: ${primarySpec()}`,
        `debug: ${debug() ? "enabled" : "disabled"}`,
        `danger rules: ${rules.builtinDenyFloor ? "enabled" : "disabled"}`,
        `protected paths: ${rules.denyPaths.length}`,
        `exempt tools: ${rules.ignoreTools.length}`,
        `nested calls: ${rules.codemodeNestedCalls}`,
        `audit: ${state.audit ? state.audit.dir : "disabled"}`,
        `confidence threshold: ${rules.classifierMinConfidence ?? "unset"}`,
        `fallback: ${rules.classifierFallbackModel ?? "unset"} (${rules.classifierFallbackMode})`,
        state.fallback.summary(rules.classifierFallbackMode),
        `integrity: ${integrity.tampered ? "blocked until restart" : "unchanged"}`,
      ];
      ctx.ui.notify(details.join("\n"), "info");
    },
  });

  function presentTamper(
    changed: Array<{ file: string; kind: WatchKind }>,
    ctx: ExtensionContext,
    cause: string,
  ) {
    const result = integrity.restoreAndFailClose(changed, cause);
    ctx.ui.notify(
      `verdict: protected files changed: ${result.files}. ${result.reason}`,
      "warning",
    );

    return {
      block: true as const,
      reason: blockedReason("tamper", result.reason),
    };
  }

  async function presentVerdict(
    value: Verdict,
    action: string,
    ctx: ExtensionContext,
  ) {
    if (debug() && value.reason.trim()) {
      ctx.ui.notify(
        debugMessage(value, action),
        value.verdict === "deny" ? "warning" : "info",
      );
    }

    if (value.verdict === "allow") return undefined;

    if (value.verdict === "deny") {
      // Protected paths stay in the local dialog, not notifications or model block reasons.
      const detail =
        value.source === "protected-path"
          ? value.reason
          : `${value.reason}\n${action}`;
      if (!debug()) {
        ctx.ui.notify(`verdict blocked: ${detail}`, "warning");
      }

      return {
        block: true as const,
        reason: blockedReason(value.source, value.reason),
      };
    }

    const protectedPath = value.source === "protected-path";
    const prompt = protectedPath
      ? `${action}\n\n${value.reason}\n\nProtected path: ${value.detail ?? "See extensionSettings.verdict"}\n\nAllow this access?`
      : `${action}\n\nClassifier decision: ${value.reason}\n\nAllow execution?`;
    const allowed = await ctx.ui.confirm(
      protectedPath ? "verdict: protected path" : "verdict: approval",
      prompt,
    );

    if (allowed) {
      return undefined;
    }

    return {
      block: true as const,
      reason: blockedReason(
        "user-declined",
        protectedPath
          ? "User declined protected-path access"
          : "User declined execution",
      ),
    };
  }

  pi.on("tool_call", async (event, ctx) => {
    if (!control.enabled) {
      return undefined;
    }

    const input = event.input as Record<string, unknown>;
    const action = toolCallLine(event.toolName, input, MAX_ACTION_CHARS);

    if (integrity.tampered) {
      return {
        block: true,
        reason: blockedReason(
          "tamper",
          "Protected files changed. Restart the session",
        ),
      };
    }

    const changed = integrity.detect();

    if (changed.length) {
      if (ctx.hasUI && changed.every(({ kind }) => kind === "config")) {
        const accept = "Accept verdict settings and continue";
        const choice = await ctx.ui.select(
          "verdict: protected settings changed",
          [accept, "Restore verdict settings and block until restart"],
        );

        if (choice === accept) {
          integrity.refreshSettingsBaseline();
          ctx.ui.notify(
            "verdict: settings accepted. New rules apply to new sessions.",
            "info",
          );
        } else {
          return presentTamper(
            changed,
            ctx,
            "Settings change was not accepted",
          );
        }
      } else {
        return presentTamper(
          changed,
          ctx,
          "Protected code changed or no approval interface is available",
        );
      }
    }

    const value = await adjudicate(
      state,
      {
        toolName: event.toolName,
        input,
        toolCallId: event.toolCallId,
        parentToolCallId: event.parentToolCallId,
      },
      {
        cwd: ctx.cwd,
        hasUI: ctx.hasUI,
        getModel: () => resolveClassifier(ctx),
        getFallbackModel: () => resolveClassifier(ctx, true),
        complete: ctx.modelRegistry.complete.bind(ctx.modelRegistry),
        classify: ctx.modelRegistry.classify.bind(ctx.modelRegistry),
        host: ctx.sessionManager,
        signal: ctx.signal,
      },
    );
    const warning = state.audit?.drainWarning();

    if (warning) {
      ctx.ui.notify(`verdict: ${warning}`, "warning");
    }

    try {
      const presented = await presentVerdict(value, action, ctx);

      if (value.pendingAudit) {
        state.audit?.append({
          ...value.pendingAudit,
          userAnswer: presented === undefined ? "allowed" : "declined",
          answeredAt: new Date().toISOString(),
        });
        value.pendingAudit = undefined;
      }

      return presented;
    } finally {
      if (value.pendingAudit) {
        state.audit?.append(value.pendingAudit);
      }

      const lateWarning = state.audit?.drainWarning();

      if (lateWarning) {
        ctx.ui.notify(`verdict: ${lateWarning}`, "warning");
      }
    }
  });
}
