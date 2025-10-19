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

  ["edit"] = {
    strategy = "chat",
    description = "Edit the current buffer",
    prompts = {
      { role = "user", content = "@{insert_edit_into_file} #{buffer}\n\n" },
    },
    opts = {
      auto_submit = false,
      short_name = "edit",
      is_slash_cmd = true,
    },
  },

  ["develop"] = {
    strategy = "chat",
    description = "Edit with full tooling",
    prompts = {
      { role = "user", content = "@{full_stack_dev} #{buffer}\n\n" },
    },
    opts = {
      auto_submit = false,
      short_name = "dev",
      is_slash_cmd = true,
    },
  },

  ["ask"] = {
    strategy = "chat",
    description = "General purpose query",
    opts = {
      auto_submit = false,
      short_name = "ask",
      is_slash_cmd = true,
      adapter = {
        name = "copilot",
        model = "gpt-4.1",
      },
      ignore_system_prompt = true,
    },
    prompts = {
      {
        role = "user",
        content = function() return "" end,
      },
    },
  },
}
