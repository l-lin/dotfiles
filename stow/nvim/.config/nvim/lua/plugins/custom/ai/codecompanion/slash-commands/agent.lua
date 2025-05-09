return {
  description = "Add agent mode",
  opts = { contains_code = false },
  ---@param chat CodeCompanion.Chat
  callback = function(chat)
    chat:replace_vars_and_tools({ content = "@full_stack_dev @mcp" })
    chat:add_reference(
      { content = require("plugins.custom.ai.prompts.agent").system(), role = "system" },
      "system-prompt",
      "<mode>agent</mode>"
    )
  end,
}

