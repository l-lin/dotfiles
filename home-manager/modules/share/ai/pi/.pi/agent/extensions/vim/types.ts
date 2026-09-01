export type CharMotion = "f" | "F" | "t" | "T";

export interface LastCharMotion {
  motion: CharMotion;
  char: string;
}

export interface MotionPosition {
  line: number;
  column: number;
}

export type WordDirection = "forward" | "backward";
export type WordTarget = "start" | "end";
