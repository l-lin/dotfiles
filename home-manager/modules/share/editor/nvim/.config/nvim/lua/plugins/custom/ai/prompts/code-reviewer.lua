return {
  kind = "role",
  tools = "@{cmd_runner}",
  system = function()
    local path = os.getenv("XDG_CONFIG_HOME") .. "/ai/commands/code-reviewer.md"
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
  end,
  user = function()
    return "Review my changes"
  end,
}
