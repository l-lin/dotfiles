import type { Plugin } from "@opencode-ai/plugin"
import { spawn } from "child_process"
import { homedir } from "os"
import { join } from "path"

const PRE_TOOL_SAFETY_SCRIPT = join(
  homedir(),
  ".config",
  "ai",
  "hooks",
  "pre-tool-safety",
  "main.rb"
)

interface RubyScriptInput {
  hook_event_name: "PreToolUse"
  tool_name: "Bash" | "Read"
  tool_input: {
    command?: string
    file_path?: string
  }
  cwd: string
}

interface RubyScriptOutput {
  hookSpecificOutput: {
    hookEventName: "PreToolUse"
    permissionDecision: "deny"
    permissionDecisionReason: string
  }
}

async function runSafetyCheck(data: RubyScriptInput): Promise<void> {
  return new Promise((resolve, reject) => {
    const child = spawn("ruby", [PRE_TOOL_SAFETY_SCRIPT])

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
        // Allow
        resolve()
      } else if (code === 2) {
        // Deny
        try {
          const output: RubyScriptOutput = JSON.parse(stdout)
          const reason = output.hookSpecificOutput.permissionDecisionReason
          reject(new Error(reason))
        } catch {
          reject(new Error("Safety check denied (failed to parse reason)"))
        }
      } else {
        reject(new Error(`Safety check failed with code ${code}: ${stderr}`))
      }
    })

    child.on("error", (err) => {
      if (err.message.includes("ENOENT")) {
        reject(
          new Error(
            `Safety check script not found at ${PRE_TOOL_SAFETY_SCRIPT}. ` +
              `Ensure home-manager has installed the script.`
          )
        )
      } else {
        reject(new Error(`Failed to run safety check: ${err.message}`))
      }
    })

    child.stdin.write(JSON.stringify(data))
    child.stdin.end()
  })
}

export const PreToolSafetyPlugin: Plugin = async ({ directory, worktree }) => {
  return {
    "tool.execute.before": async (input, output) => {
      const tool = input.tool.toLowerCase()

      if (tool !== "bash" && tool !== "read") {
        return
      }

      // Skip check if required arguments are missing
      if (tool === "bash" && !output.args.command) {
        return
      }
      if (tool === "read" && !output.args.filePath) {
        return
      }

      // Sanitize tool, because the ruby script is using claude-code input/output.
      const toolName = tool === "bash" ? "Bash" : "Read"

      const cwd = directory || worktree

      // Build tool_input based on tool type
      const toolInput: { command?: string; file_path?: string } = {}

      if (tool === "bash") {
        toolInput.command = output.args.command
      } else if (tool === "read") {
        toolInput.file_path = output.args.filePath
      }

      const rubyInput: RubyScriptInput = {
        hook_event_name: "PreToolUse",
        tool_name: toolName,
        tool_input: toolInput,
        cwd,
      }

      await runSafetyCheck(rubyInput)
    },
  }
}
