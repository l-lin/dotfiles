return {
  description = "Assistant with visible thinking process",
  opts = { contains_code = false },
  ---@param chat CodeCompanion.Chat
  callback = function(chat)
    chat:add_reference(
      { content = require("plugins.custom.ai.prompts.thinking").system(), role = "system" },
      "system-prompt",
      "<mode>thinking</mode>"
    )
  end,
}

