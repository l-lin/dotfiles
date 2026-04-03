import { complete, type UserMessage } from "@mariozechner/pi-ai";
import type {
  ExtensionAPI,
  ExtensionContext,
  SessionEntry,
} from "@mariozechner/pi-coding-agent";
import {
  BorderedLoader,
  convertToLlm,
  serializeConversation,
} from "@mariozechner/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";
import { ModelPickerComponent } from "./model-picker.js";
import { OracleResultComponent } from "./result-component.js";
import type { AvailableModel } from "./types.js";

const SYSTEM_PROMPT = `You are providing a second opinion on a coding conversation. 
You have access to the full conversation context between the user and their primary AI assistant.
Your job is to:
1. Understand what they've been discussing
2. Answer the specific question they're asking you
3. Point out if you disagree with any decisions made
4. Be concise but thorough

Focus on being helpful and providing a fresh perspective.`;

export function showModelPicker(
  ctx: ExtensionContext,
  availableModels: AvailableModel[],
  prompt: string,
  files: string[],
): Promise<AvailableModel | null> {
  return ctx.ui.custom<AvailableModel | null>((tui, _theme, _kb, done) => {
    const c = new ModelPickerComponent(
      availableModels,
      prompt,
      files,
      tui,
      done,
      () => done(null),
    );
    return {
      render: (w) => c.render(w),
      invalidate: () => c.invalidate(),
      handleInput: (d) => c.handleInput(d),
    };
  });
}

function buildFullPrompt(
  ctx: ExtensionContext,
  prompt: string,
  files: string[],
): string {
  const messages = ctx.sessionManager
    .getBranch()
    .filter(
      (e): e is SessionEntry & { type: "message" } => e.type === "message",
    )
    .map((e) => e.message);

  let fullPrompt = "";
  if (messages.length > 0) {
    fullPrompt += `## Current Conversation Context\n\n${serializeConversation(convertToLlm(messages))}\n\n`;
  }
  fullPrompt += `## Question for Second Opinion\n\n${prompt}`;

  for (const file of files) {
    try {
      const content = fs.readFileSync(path.resolve(ctx.cwd, file), "utf-8");
      fullPrompt += `\n\n--- File: ${file} ---\n${content}`;
    } catch (err) {
      fullPrompt += `\n\n--- File: ${file} ---\n[Error reading file: ${err}]`;
    }
  }
  return fullPrompt;
}

export function getOracleRequestOptions(
  model: AvailableModel,
  signal: AbortSignal,
): { signal: AbortSignal; apiKey?: string; headers?: Record<string, string> } {
  return {
    signal,
    apiKey: model.apiKey,
    headers: model.headers,
  };
}

function queryModel(
  ctx: ExtensionContext,
  model: AvailableModel,
  fullPrompt: string,
): Promise<string | null> {
  return ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
    const loader = new BorderedLoader(tui, theme, `🔮 Asking ${model.name}...`);
    loader.onAbort = () => done(null);

    const userMessage: UserMessage = {
      role: "user",
      content: [{ type: "text", text: fullPrompt }],
      timestamp: Date.now(),
    };

    complete(
      model.model,
      { systemPrompt: SYSTEM_PROMPT, messages: [userMessage] },
      getOracleRequestOptions(model, loader.signal),
    )
      .then((response) => {
        if (response.stopReason === "aborted") return done(null);
        const text = response.content
          .filter((c): c is { type: "text"; text: string } => c.type === "text")
          .map((c) => c.text)
          .join("\n");
        done(text);
      })
      .catch((err) => {
        console.error("Oracle error:", err);
        done(null);
      });

    return loader;
  });
}

function showResult(
  ctx: ExtensionContext,
  result: string,
  modelName: string,
  prompt: string,
): Promise<boolean> {
  return ctx.ui.custom<boolean>((tui, _theme, _kb, done) => {
    const c = new OracleResultComponent(result, modelName, prompt, tui, done);
    return {
      render: (w) => c.render(w),
      invalidate: () => c.invalidate(),
      handleInput: (d) => c.handleInput(d),
    };
  });
}

export async function executeOracle(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  prompt: string,
  files: string[],
  model: AvailableModel,
): Promise<void> {
  const result = await queryModel(
    ctx,
    model,
    buildFullPrompt(ctx, prompt, files),
  );

  if (result === null) {
    ctx.ui.notify("Cancelled or failed", "warning");
    return;
  }

  if (await showResult(ctx, result, model.name, prompt)) {
    pi.sendMessage({
      customType: "oracle-response",
      content: result,
      display: true,
      details: { model: model.modelId, modelName: model.name, files, prompt },
    });
    ctx.ui.notify("Oracle response added to context", "info");
  } else {
    ctx.ui.notify("Oracle response discarded", "info");
  }
}
