return {
  kind = "role",
  tools = "@{get_changed_files}",
  system = function()
    local path = os.getenv("XDG_CONFIG_HOME") .. "/ai/agents/code-reviewer.md"
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
  end,
  user = function()
    return "Review the code changes"
  end,
}
