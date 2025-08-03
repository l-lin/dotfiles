-- Starting the index at 30 to ensure all my custom prompts appear at the bottom.
local idx = 30
local function index()
  idx = idx + 1
  return idx
end

return {
  --
  -- LANGUAGE
  --

  ["english@inline"] = {
    strategy = "inline",
    description = "Improve English wording and grammar",
    opts = {
      auto_submit = false,
      index = index(),
      is_slash_cmd = true,
      modes = { "v" },
      short_name = "english",
      stop_context_insertion = true,
      user_prompt = false,
    },
    prompts = {
      {
        role = "system",
        content = require("plugins.custom.ai.prompts.english-enhancer").system(),
      },
      {
        role = "user",
        content = function(context)
          local text = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
          return require("plugins.custom.ai.prompts.english-enhancer").user(text)
        end,
      },
    },
  },

  --
  -- CODE
  --

  ["refactor@inline"] = {
    strategy = "inline",
    description = "Refactor the provided code snippet.",
    opts = {
      index = index(),
      modes = { "v" },
      short_name = "inline-refactor",
      auto_submit = true,
      user_prompt = false,
      stop_context_insertion = true,
    },
    prompts = {
      {
        role = "system",
        opts = { visible = false },
        content = require("plugins.custom.ai.prompts.refactor").system,
      },
      {
        role = "user",
        opts = { contains_code = true },
        content = function(context)
          local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
          return require("plugins.custom.ai.prompts.refactor").user(context.filetype, code)
        end,
      },
    },
  },
  ["java-unit-tests@chat"] = {
    strategy = "chat",
    description = "Implement Java unit tests for the selected code.",
    opts = {
      index = index(),
      is_slash_cmd = false,
      modes = { "v" },
      short_name = "java-unit-test",
      auto_submit = false,
      user_prompt = false,
      stop_context_insertion = true,
    },
    prompts = {
      {
        role = "system",
        opts = { visible = false },
        content = require("plugins.custom.ai.prompts.java-tests").system(),
      },
      {
        role = "user",
        opts = { contains_code = true },
        content = function(context)
          local code = require("codecompanion.helpers.actions").get_code(context.start_line, context.end_line)
          return require("plugins.custom.ai.prompts.java-tests").user(code)
        end,
      },
    },
  },
  ["swe@workflow"] = {
    strategy = "workflow",
    description = "Use a workflow to guide an LLM in writing code to implement a feature or a bugfix",
    opts = {
      index = index(),
      short_name = "workflow-implement",
      adapter = { name = "copilot" },
    },
    prompts = {
      {
        {
          role = "system",
          opts = { visible = false },
          content = require("plugins.custom.ai.prompts.swe").system(),
        },
        {
          role = "user",
          opts = { auto_submit = false },
          content = function()
            vim.g.codecompanion_auto_tool_mode = true
            return require("plugins.custom.ai.prompts.swe").user()
          end,
        },
      },
      {
        {
          name = "Repeat On Failure",
          role = "user",
          opts = { auto_submit = true },
          -- Scope this prompt to the cmd_runner tool
          condition = function()
            return _G.codecompanion_current_tool == "cmd_runner"
          end,
          -- Repeat until the tests pass, as indicated by the testing flag
          -- which the cmd_runner tool sets on the chat buffer
          ---@param chat CodeCompanion.Chat
          repeat_until = function(chat)
            return chat.tools.flags.testing == true
          end,
          content = "The tests have failed. Can you edit the buffer and run the test suite again?",
        },
      },
    },
  },
}
