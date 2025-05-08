return {
  description = "Add Project Owner role",
  opts = { contains_code = false },
  ---@param chat CodeCompanion.Chat
  callback = function(chat)
    chat:replace_vars_and_tools({ content = "@files" })
    chat:add_reference(
      { content = require("plugins.custom.ai.prompts.specifications").system(), role = "system" },
      "system-prompt",
      "<role>po</role>"
    )
    chat:add_buf_message({
      content = require("plugins.custom.ai.prompts.specifications").user(),
      role = "user"
    })
  end,
}
