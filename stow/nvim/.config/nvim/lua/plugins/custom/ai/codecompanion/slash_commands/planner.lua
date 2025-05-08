return {
  description = "Add planner role",
  opts = { contains_code = false },
  ---@param chat CodeCompanion.Chat
  callback = function(chat)
    chat:replace_vars_and_tools({ content = "@files" })
    chat:add_reference(
      { content = require("plugins.custom.ai.prompts.planner").system(), role = "system" },
      "system-prompt",
      "<role>planner</role>"
    )
    chat:add_buf_message({
      content = require("plugins.custom.ai.prompts.planner").user(),
      role = "user"
    })
  end,
}
