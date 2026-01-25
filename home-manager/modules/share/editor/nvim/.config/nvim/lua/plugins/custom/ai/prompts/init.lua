--
-- List of system prompts for AI tools.
-- Prompt tips:
-- - https://www.adithyan.io/blog/writing-cursor-rules-with-a-cursor-rule
-- - https://stal.blogspot.com/2025/04/prompt-engineering-techniques.html
-- - https://www.anthropic.com/engineering/claude-code-best-practices
-- - https://cookbook.openai.com/examples/gpt4-1_prompting_guide
-- - https://github.com/EnzeD/vibe-coding
-- - https://manuel.kiessling.net/2025/03/31/how-seasoned-developers-can-achieve-great-results-with-ai-coding-agents/
-- - https://harper.blog/2025/02/16/my-llm-codegen-workflow-atm/
--
-- Prompt examples:
-- - https://github.com/olimorris/codecompanion.nvim/blob/de312b952235a5e2ab9355b0fcbfdbbd5fafa5cf/lua/codecompanion/config.lua#L1008-L1039
-- - https://github.com/CopilotC-Nvim/CopilotChat.nvim/blob/75653259442a8eb895abfc70d7064e07aeb7134c/lua/CopilotChat/config/prompts.lua#L1-L31
-- - https://github.com/yingmanwumen/nvim/blob/8e25d926f8e011ca65cd2c65aeaab8f912a4eb17/lua/plugins/ai/codecompanion/system_prompt.lua
-- - https://majesticlabs.dev/blog/202502/rules_for_ai.txt
-- - https://dev.to/dpaluy/mastering-cursor-rules-a-developers-guide-to-smart-ai-integration-1k65
-- - https://github.com/asgeirtj/system_prompts_leaks/blob/main/claude.txt
-- - https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools
-- - https://cursor.directory/
-- - https://github.com/PatrickJS/awesome-cursorrules
--

---@class l-lin.Prompt
---@field name string the prompt name
---@field kind string the prompt kind (one of "role" or "action")
---@field tools string the tools to use for the prompt
---@field system function the system prompt to add
---@field user function the user prompt to pre-fill

---@return l-lin.Prompt[] prompts all the prompts found in the directory `/nvim/lua/plugins/custom/ai/commands/`
local function global_prompts()
  local prompts = {}
  local current_dir = os.getenv("XDG_CONFIG_HOME") .. "/nvim/lua/plugins/custom/ai/commands/"
  local stdout = io.popen("ls " .. current_dir)

  if not stdout then
    return prompts
  end

  while true do
    local line = stdout:read("*line")
    if not line then
      break
    end

    local prompt_name = line:gsub(".lua", "")
    if prompt_name ~= "init" and prompt_name ~= "system-prompt" then
      local prompt = require("plugins.custom.ai.prompts." .. prompt_name)
      prompt.name = prompt_name
      table.insert(prompts, prompt)
    end
  end
  stdout:close()
  return prompts
end

---@return l-lin.Prompt[] project_prompts all the prompts found in the current project
local function project_prompts()
  local prompts = {}

  -- No need to find the root directory based on a root marker (e.g. a `.git`
  -- directory), as I'm always opening codecompanion from the project root
  -- directory.
  local current_dir = vim.fn.getcwd()
  local project_commands_dir = current_dir .. "/.ai/commands/"

  if vim.fn.isdirectory(project_commands_dir) == 0 then
    return prompts
  end

  local prompt_files = vim.fn.glob(project_commands_dir .. "*.md", false, true)

  for _, file_path in ipairs(prompt_files) do
    local filename_without_ext = vim.fn.fnamemodify(file_path, ":t:r")

    local file = assert(io.open(file_path, "r"))
    local content = file:read("*a")
    file:close()

    local prompt = {
      name = filename_without_ext,
      kind = "action",
      tools = "",
      system = function() return content end,
      user = function() return "" end,
    }
    table.insert(prompts, prompt)
  end

  return prompts
end

local M = {}
M.global_prompts = global_prompts
M.project_prompts = project_prompts
return M
