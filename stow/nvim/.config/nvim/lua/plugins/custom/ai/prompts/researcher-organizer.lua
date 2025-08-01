return {
  kind = "role",
  tools = "@{files} @{web_search} @{fetch_webpage} #{buffer}",
  system = function()
    local path = os.getenv("XDG_CONFIG_HOME") .. "/ai/agents/researcher-organizer.md"
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
  end,
  user = function()
    return ""
  end,
}
