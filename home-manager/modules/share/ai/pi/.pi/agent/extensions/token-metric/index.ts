import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

import { engine } from "./engine.js";
import {
  EMPTY_TOKEN_METRIC_SNAPSHOT,
  TOKEN_METRIC_CHANGED_EVENT,
  type TokenMetricSnapshot,
} from "./events.js";

const SNAPSHOT_INTERVAL_MS = 100;

export default function (pi: ExtensionAPI) {
  let snapshotInterval: NodeJS.Timeout | null = null;

  function emitSnapshot(snapshot: TokenMetricSnapshot): void {
    pi.events.emit(TOKEN_METRIC_CHANGED_EVENT, snapshot);
  }

  function buildCurrentSnapshot(): TokenMetricSnapshot {
    if (engine.tokenCount === 0 || engine.elapsedMs <= 0) {
      return EMPTY_TOKEN_METRIC_SNAPSHOT;
    }

    return { tps: engine.tps };
  }

  function publishCurrentSnapshot(): void {
    emitSnapshot(buildCurrentSnapshot());
  }

  function resetSnapshot(): void {
    emitSnapshot(EMPTY_TOKEN_METRIC_SNAPSHOT);
  }

  function stopSnapshotInterval(): void {
    if (snapshotInterval === null) return;
    clearInterval(snapshotInterval);
    snapshotInterval = null;
  }

  function startSnapshotInterval(): void {
    stopSnapshotInterval();
    snapshotInterval = setInterval(() => {
      publishCurrentSnapshot();
    }, SNAPSHOT_INTERVAL_MS);
  }

  function finalizeStream(outputTokens: number | undefined): void {
    if (!engine.isStreaming) return;

    engine.reconcileTotal(outputTokens ?? 0);
    engine.stop();
    publishCurrentSnapshot();
    stopSnapshotInterval();
    resetSnapshot();
  }

  pi.on("session_start", async () => {
    await engine.initialize();
    stopSnapshotInterval();
    resetSnapshot();
  });

  pi.on("agent_start", async () => {
    resetSnapshot();
  });

  pi.on("message_start", async (event) => {
    if (event.message?.role === "user") {
      engine.startTTFT();
    }

    if (event.message?.role === "assistant") {
      engine.start();
      resetSnapshot();
      startSnapshotInterval();
    }
  });

  pi.on("message_update", (event) => {
    const ev = event.assistantMessageEvent;

    if (
      ev.type === "text_start" ||
      ev.type === "thinking_start" ||
      ev.type === "toolcall_start"
    ) {
      engine.stopTTFT();
    }

    if (
      ev.type === "text_delta" ||
      ev.type === "thinking_delta" ||
      ev.type === "toolcall_delta"
    ) {
      engine.recordDelta(ev.delta, ev.partial?.usage?.output);
      publishCurrentSnapshot();
    }
  });

  pi.on("message_end", async (event) => {
    if (event.message?.role !== "assistant") return;
    finalizeStream(event.message?.usage?.output ?? 0);
  });

  pi.on("turn_end", async () => {
    finalizeStream(undefined);
  });

  pi.on("session_shutdown", async () => {
    stopSnapshotInterval();
    if (engine.isStreaming) {
      engine.stop();
    }
  });
}
