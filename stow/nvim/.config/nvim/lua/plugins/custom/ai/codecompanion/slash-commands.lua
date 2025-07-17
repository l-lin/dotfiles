---@param prompt_name string the prompt name
---@param prompt l-lin.Prompt the prompt
---@return table slash_command the slash command converted from the prompt
local function slash_command_from(prompt_name, prompt)
  return {
    description = "Add " .. prompt_name .. " " .. prompt.kind,
    opts = { contains_code = false },
    ---@param chat CodeCompanion.Chat
    callback = function(chat)
      chat:replace_vars_and_tools({ content = prompt.tools })
      if prompt.kind == "role" or prompt.kind == "action" then
        chat:add_reference(
          { content = prompt.system(), role = "system" },
          "system-prompt",
          string.format("<%s>%s</%s>", prompt.kind, prompt_name, prompt.kind)
        )
      end
      chat:add_buf_message({ content = prompt.user(), role = "user" })
    end,
  }
end


local function all_slash_commands()
  local roles = {}

  local prompts_module = require("plugins.custom.ai.prompts")
  local all_prompts = {}
  vim.list_extend(all_prompts, prompts_module.global_prompts() or {})
  vim.list_extend(all_prompts, prompts_module.project_prompts() or {})

  for _, prompt in pairs(all_prompts) do
    if prompt then
      roles[prompt.kind .. ":" .. prompt.name] = slash_command_from(prompt.name, prompt)
    end
  end

  return roles
end

local M = {
}
for role_name, slash_command in pairs(all_slash_commands()) do
  M[role_name] = slash_command
end
return M
