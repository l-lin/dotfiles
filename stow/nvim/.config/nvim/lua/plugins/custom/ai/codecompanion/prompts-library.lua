-- Starting the index at 30 to ensure all my custom prompts appear at the bottom.
local idx = 30
local function index()
  idx = idx + 1
  return idx
end

return {
  --
  -- CODE
  --

  ["edit"] = {
    strategy = "chat",
    description = "Edit the current buffer",
    prompts = {
      { role = "user", content = "@{insert_edit_into_file} #{buffer}\n\n" },
    },
    opts = {
      index = index(),
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
      index = index(),
      auto_submit = false,
      short_name = "dev",
      is_slash_cmd = true,
    },
  },

  ["ask"] = {
    strategy = "chat",
    description = "General purpose query",
    opts = {
      index = index(),
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
