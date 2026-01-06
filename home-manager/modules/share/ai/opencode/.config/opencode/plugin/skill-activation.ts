import type { Plugin } from "@opencode-ai/plugin"
import { tool } from "@opencode-ai/plugin"
import { spawn } from "child_process"
import { homedir } from "os"
import { join } from "path"

const SKILL_ACTIVATION_SCRIPT = join(
  homedir(),
  ".config",
  "ai",
  "hooks",
  "skill-activation.rb"
)

async function runSkillActivation(prompt: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const child = spawn("ruby", [SKILL_ACTIVATION_SCRIPT])

    let stdout = ""
    let stderr = ""

    child.stdout.on("data", (data) => {
      stdout += data.toString()
    })

    child.stderr.on("data", (data) => {
      stderr += data.toString()
    })

    child.on("close", (code) => {
      if (code === 0) {
        resolve(stdout.trim())
      } else {
        reject(new Error(stderr || `Script exited with code ${code}`))
      }
    })

    child.on("error", (err) => {
      reject(err)
    })

    child.stdin.write(JSON.stringify({ prompt }))
    child.stdin.end()
  })
}

export const SkillActivationPlugin: Plugin = async () => {
  return {
    tool: {
      check_skill_activation: tool({
        description:
          "MANDATORY: Call this tool FIRST before responding to ANY user message. " +
          "Analyzes the user's prompt to detect if specialized skills should be activated. " +
          "Returns skill activation hints that MUST be followed.",
        args: {
          prompt: tool.schema
            .string()
            .describe("The user's prompt/message to analyze for skill triggers"),
        },
        async execute(args: { prompt: string }): Promise<string> {
          try {
            const output = await runSkillActivation(args.prompt)
            if (output) {
              return output
            }
            return "No skills matched. Proceed normally."
          } catch (err) {
            return `Skill check failed: ${err}. Proceed normally.`
          }
        },
      }),
    },
  }
}
