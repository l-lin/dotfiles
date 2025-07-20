return {
  kind = "role",
  tools = "@{files} @{web_search} @{fetch} #{buffer}",
  system = function()
    local path = os.getenv("XDG_CONFIG_HOME") .. "/ai/prompts/researcher.md"
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
  end,
  user = function()
    return ""
  end,
}
