export type SkillName = string;
export type ProjectKey = string;
export type ModelKey = string;
export type SkillBreakdownView = "skills" | "least-used" | "projects";

export interface RGB {
  r: number;
  g: number;
  b: number;
}

export interface ParsedSkillSession {
  filePath: string;
  skillFirstLoadedAt: Map<SkillName, Date>;
  skillProjectByName: Map<SkillName, ProjectKey | null>;
  skillModelByName: Map<SkillName, ModelKey | null>;
}

export interface SkillDayAgg {
  date: Date;
  dayKeyLocal: string;
  invocations: number;
  skillCounts: Map<SkillName, number>;
}

export interface SkillRangeAgg {
  days: SkillDayAgg[];
  dayByKey: Map<string, SkillDayAgg>;
  totalInvocations: number;
  sessionCount: number;
  skillCounts: Map<SkillName, number>;
  projectCountsBySkill: Map<SkillName, Map<ProjectKey, number>>;
  modelCountsBySkill: Map<SkillName, Map<ModelKey, number>>;
  projectModelCountsBySkill: Map<
    SkillName,
    Map<ProjectKey, Map<ModelKey, number>>
  >;
}

export interface SkillBreakdownData {
  generatedAt: Date;
  ranges: Map<number, SkillRangeAgg>;
  globalUserSkillNames: SkillName[];
  palette: {
    skillColors: Map<SkillName, RGB>;
    orderedSkills: SkillName[];
    otherColor: RGB;
  };
}

export type SkillBreakdownProgressPhase = "scan" | "parse" | "finalize";

export interface SkillBreakdownProgressState {
  phase: SkillBreakdownProgressPhase;
  foundFiles: number;
  parsedFiles: number;
  totalFiles: number;
  currentFile?: string;
}
