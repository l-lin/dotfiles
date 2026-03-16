export type ModelKey = string; // `${provider}/${model}`
export type CwdKey = string; // normalized cwd path
export type DowKey = string; // "Mon", "Tue", etc.
export type TodKey = string; // "after-midnight", "morning", "afternoon", "evening", "night"
export type BreakdownView = "model" | "cwd" | "dow" | "tod";

export interface ParsedSession {
  filePath: string;
  startedAt: Date;
  dayKeyLocal: string; // YYYY-MM-DD (local)
  cwd: CwdKey | null;
  dow: DowKey;
  tod: TodKey;
  modelsUsed: Set<ModelKey>;
  messages: number;
  tokens: number;
  totalCost: number;
  costByModel: Map<ModelKey, number>;
  messagesByModel: Map<ModelKey, number>;
  tokensByModel: Map<ModelKey, number>;
}

export interface DayAgg {
  date: Date; // local midnight
  dayKeyLocal: string;
  sessions: number;
  messages: number;
  tokens: number;
  totalCost: number;
  costByModel: Map<ModelKey, number>;
  sessionsByModel: Map<ModelKey, number>;
  messagesByModel: Map<ModelKey, number>;
  tokensByModel: Map<ModelKey, number>;
  sessionsByCwd: Map<CwdKey, number>;
  messagesByCwd: Map<CwdKey, number>;
  tokensByCwd: Map<CwdKey, number>;
  costByCwd: Map<CwdKey, number>;
  sessionsByTod: Map<TodKey, number>;
  messagesByTod: Map<TodKey, number>;
  tokensByTod: Map<TodKey, number>;
  costByTod: Map<TodKey, number>;
}

export interface RangeAgg {
  days: DayAgg[];
  dayByKey: Map<string, DayAgg>;
  sessions: number;
  totalMessages: number;
  totalTokens: number;
  totalCost: number;
  modelCost: Map<ModelKey, number>;
  modelSessions: Map<ModelKey, number>; // number of sessions where model was used
  modelMessages: Map<ModelKey, number>;
  modelTokens: Map<ModelKey, number>;
  cwdCost: Map<CwdKey, number>;
  cwdSessions: Map<CwdKey, number>;
  cwdMessages: Map<CwdKey, number>;
  cwdTokens: Map<CwdKey, number>;
  dowCost: Map<DowKey, number>;
  dowSessions: Map<DowKey, number>;
  dowMessages: Map<DowKey, number>;
  dowTokens: Map<DowKey, number>;
  todCost: Map<TodKey, number>;
  todSessions: Map<TodKey, number>;
  todMessages: Map<TodKey, number>;
  todTokens: Map<TodKey, number>;
}

export interface RGB {
  r: number;
  g: number;
  b: number;
}

export interface BreakdownData {
  generatedAt: Date;
  ranges: Map<number, RangeAgg>;
  palette: {
    modelColors: Map<ModelKey, RGB>;
    otherColor: RGB;
    orderedModels: ModelKey[];
  };
  cwdPalette: {
    cwdColors: Map<CwdKey, RGB>;
    otherColor: RGB;
    orderedCwds: CwdKey[];
  };
  dowPalette: {
    dowColors: Map<DowKey, RGB>;
    orderedDows: DowKey[];
  };
  todPalette: {
    todColors: Map<TodKey, RGB>;
    orderedTods: TodKey[];
  };
}

export type MeasurementMode = "sessions" | "messages" | "tokens";

export type BreakdownProgressPhase = "scan" | "parse" | "finalize";

export interface BreakdownProgressState {
  phase: BreakdownProgressPhase;
  foundFiles: number;
  parsedFiles: number;
  totalFiles: number;
  currentFile?: string;
}
