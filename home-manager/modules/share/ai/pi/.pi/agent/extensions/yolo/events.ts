export const YOLO_SET_SANDBOX_ENABLED_EVENT = "yolo:set-sandbox-enabled";
export const YOLO_SET_DAMAGE_CONTROL_ENABLED_EVENT =
  "yolo:set-damage-control-enabled";

export interface YoloToggleStateChangedEvent {
  enabled: boolean;
  cwd: string;
}

export function readYoloToggleStateChangedEvent(
  value: unknown,
): YoloToggleStateChangedEvent | undefined {
  if (typeof value !== "object" || value === null) {
    return undefined;
  }

  const candidate = value as Record<string, unknown>;

  if (typeof candidate.enabled !== "boolean") {
    return undefined;
  }

  if (typeof candidate.cwd !== "string") {
    return undefined;
  }

  return {
    enabled: candidate.enabled,
    cwd: candidate.cwd,
  };
}
