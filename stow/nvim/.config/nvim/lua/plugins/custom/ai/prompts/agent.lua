return {
  kind = "role",
  tools = "@{full_stack_dev} @{plan}",
  system = function ()
    return ""
  end,
  user = function ()
    vim.g.codecompanion_auto_tool_mode = true
    return ""
  end
}
