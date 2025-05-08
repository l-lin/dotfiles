return {
  description = "Add Investigator role",
  opts = { contains_code = false },
  ---@param chat CodeCompanion.Chat
  callback = function(chat)
    chat:replace_vars_and_tools({ content = "@files @cmd_runner @vectorcode @mcp" })
    chat:add_reference(
      { content = require("plugins.custom.ai.prompts.investigator").system(), role = "system" },
      "system-prompt",
      "<role>investigator</role>"
    )
  end,
}

