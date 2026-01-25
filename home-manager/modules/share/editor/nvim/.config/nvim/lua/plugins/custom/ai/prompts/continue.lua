return {
  kind = "action",
  tools = "",
  system = function()
    local path = os.getenv("XDG_CONFIG_HOME") .. "/ai/commands/continue.md"
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
  end,
  user = function()
    return ""
  end,
}
