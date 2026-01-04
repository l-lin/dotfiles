return {
  kind = "role",
  tools = "@{full_stack_dev} @{plan}",
  system = function ()
    return ""
  end,
  user = function ()
    vim.g.codecompanion_yolo_mode = true
    return ""
  end
}
