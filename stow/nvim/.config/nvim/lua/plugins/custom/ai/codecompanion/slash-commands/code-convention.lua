local function read_code_convention()
  return string.format([[Follow the following code convention:
<code_convention>
%s
</code_convention>
    ]], vim.fn.readfile(vim.env.HOME .. "/.config/ai/conventions/code.md"))
end

return {
  description = "Add code convention",
  opts = { contains_code = false },
  ---@param chat CodeCompanion.Chat
  callback = function(chat)
    chat:add_reference(
      { content = read_code_convention(), role = "system" },
      "system-prompt",
      "<convention>code</convention>"
    )
  end,
}
