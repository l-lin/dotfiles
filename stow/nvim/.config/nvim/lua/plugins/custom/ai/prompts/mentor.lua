-- Shamelessly copied and adapted from https://github.com/github/awesome-copilot/blob/main/chatmodes/mentor.chatmode.md

return {
  kind = "role",
  tools = "",
  system = function()
    local path = os.getenv("XDG_CONFIG_HOME") .. "/ai/prompts/mentor.md"
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
  end,
  user = function()
    return ""
  end,
}
