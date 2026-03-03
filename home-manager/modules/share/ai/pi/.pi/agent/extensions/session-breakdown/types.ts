export type ModelKey = string; // `${provider}/${model}`

export interface ParsedSession {
  filePath: string;
  startedAt: Date;
  dayKeyLocal: string; // YYYY-MM-DD (local)
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
