return {
  description = "Add English Enhancer role",
  opts = { contains_code = false },
  ---@param chat CodeCompanion.Chat
  callback = function(chat)
    chat:add_reference(
      { content = require("plugins.custom.ai.prompts.english-enhancer").system(), role = "system" },
      "system-prompt",
      "<role>english-enhancer</role>"
    )
  end,
}

