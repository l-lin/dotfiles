// ============================================================================
// Ask-User-Question Extension — Type Definitions & Schema
// ============================================================================

import { Type } from "@sinclair/typebox";

export interface Question {
  id: string;
  label: string;
  prompt: string;
  options: { value: string; label: string; description?: string }[];
}

export interface Answer {
  id: string;
  value: string;
  label: string;
  wasCustom: boolean;
  index?: number;
}

export interface Result {
  questions: Question[];
  answers: Answer[];
  cancelled: boolean;
}

export const QuestionnaireParams = Type.Object({
  questions: Type.Array(
    Type.Object({
      id: Type.String({ description: "Unique identifier for this question" }),
      label: Type.Optional(
        Type.String({
          description: "Short label for tab bar (defaults to Q1, Q2)",
        }),
      ),
      prompt: Type.String({ description: "The question text to display" }),
      options: Type.Array(
        Type.Object({
          value: Type.String({ description: "Value returned when selected" }),
          label: Type.String({ description: "Display label" }),
          description: Type.Optional(
            Type.String({ description: "Optional description" }),
          ),
        }),
        { description: "Available options" },
      ),
    }),
    { description: "Questions to ask" },
  ),
});

export function error(msg: string) {
  return {
    content: [{ type: "text" as const, text: `Error: ${msg}` }],
    details: { questions: [], answers: [], cancelled: true } as Result,
  };
}
