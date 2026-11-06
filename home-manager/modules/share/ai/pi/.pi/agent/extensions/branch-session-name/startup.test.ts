import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { promisify } from "node:util";
import {
  createAgentSessionFromServices,
  createAgentSessionRuntime,
  createAgentSessionServices,
  SessionManager,
  type CreateAgentSessionRuntimeFactory,
} from "@earendil-works/pi-coding-agent";
import branchSessionName from "./index.js";

const exec = promisify(execFile);

test(
  "GIVEN a saved branch conversation WHEN Pi starts THEN the real runtime resumes it without a model request",
  { timeout: 10000 },
  async (t) => {
    const cwd = mkdtempSync(join(tmpdir(), "branch-session-runtime-"));
    t.after(() => rmSync(cwd, { recursive: true, force: true }));
    const branch = "feature/startup-resume";
    await exec("git", ["init", `--initial-branch=${branch}`], { cwd });
    const sessionDir = join(cwd, "sessions");
    const saved = SessionManager.create(cwd, sessionDir);
    saved.appendSessionInfo(branch);
    saved.appendMessage({
      role: "user",
      content: "Restore this conversation",
      timestamp: 1000,
    });
    const errors: string[] = [];
    const starts: string[] = [];
    let startupFinished = false;
    let finished!: () => void;
    const resumed = new Promise<void>((resolve) => {
      finished = resolve;
    });
    const given_runtime: CreateAgentSessionRuntimeFactory = async ({
      cwd,
      agentDir,
      sessionManager,
      sessionStartEvent,
    }) => {
      const services = await createAgentSessionServices({
        cwd,
        agentDir,
        resourceLoaderOptions: {
          noExtensions: true,
          noSkills: true,
          noThemes: true,
          noPromptTemplates: true,
          noContextFiles: true,
          extensionFactories: [
            branchSessionName,
            (pi) => {
              pi.on("session_start", async (event) => {
                starts.push(event.reason);
                if (event.reason === "startup") {
                  await new Promise<void>((resolve) => setTimeout(resolve, 10));
                  startupFinished = true;
                }
              });
            },
          ],
        },
      });
      return {
        ...(await createAgentSessionFromServices({
          services,
          sessionManager,
          sessionStartEvent,
          noTools: "all",
        })),
        services,
        diagnostics: services.diagnostics,
      };
    };
    const runtime = await createAgentSessionRuntime(given_runtime, {
      cwd,
      agentDir: join(cwd, "agent"),
      sessionManager: SessionManager.create(cwd, sessionDir),
    });
    t.after(() => runtime.dispose());
    const when_binding = async () => {
      await runtime.session.bindExtensions({
        mode: "tui",
        onError: (error) => {
          errors.push(error.error);
        },
        commandContextActions: {
          waitForIdle: () => runtime.session.waitForIdle(),
          newSession: (options) => runtime.newSession(options),
          fork: (entryId, options) => runtime.fork(entryId, options),
          navigateTree: (targetId, options) =>
            runtime.session.navigateTree(targetId, options),
          reload: () => runtime.session.reload(),
          switchSession: async (path, options) => {
            assert.equal(startupFinished, true);
            const result = await runtime.switchSession(path, options);
            finished();
            return result;
          },
        },
      });
    };
    runtime.setRebindSession(when_binding);
    await when_binding();
    await resumed;
    const actual = {
      file: runtime.session.sessionFile,
      name: runtime.session.sessionManager.getSessionName(),
      messages: runtime.session.messages.filter(
        (message) => message.role === "user",
      ),
      starts,
      errors,
    };
    const expected = {
      file: saved.getSessionFile(),
      name: branch,
      messages: [
        { role: "user", content: "Restore this conversation", timestamp: 1000 },
      ],
      starts: ["startup", "resume"],
      errors: [],
    };
    assert.deepEqual(actual, expected);
  },
);
