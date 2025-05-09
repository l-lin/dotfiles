return {
  description = "Add conventional git commit convention",
  opts = { contains_code = false },
  ---@param chat CodeCompanion.Chat
  callback = function(chat)
    chat:replace_vars_and_tools({ content = "@cmd_runner" })
    chat:add_reference(
      { content = require("plugins.custom.ai.prompts.git-commit").system(), role = "system" },
      "system-prompt",
      "<convention>git</convention>"
    )
    chat:add_buf_message({
      content = require("plugins.custom.ai.prompts.git-commit").user(),
      role = "user",
    })
  end
}
