return {
  kind = "role",
  tools = "",
  system = function()
    local path = os.getenv("XDG_CONFIG_HOME") .. "/ai/commands/humanizer.md"
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
  end,
  user = function()
    return ""
  end,
}
