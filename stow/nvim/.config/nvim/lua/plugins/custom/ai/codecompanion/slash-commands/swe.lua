return {
  description = "Add Software Engineer role",
  opts = { contains_code = false },
  ---@param chat CodeCompanion.Chat
  callback = function(chat)
    chat:replace_vars_and_tools({ content = "@full_stack_dev" })
    chat:add_reference(
      { content = require("plugins.custom.ai.prompts.swe").system(), role = "system" },
      "system-prompt",
      "<role>swe</role>"
    )
    require("plugins.custom.ai.codecompanion.slash-commands.code-convention").callback(chat)
  end,
}

