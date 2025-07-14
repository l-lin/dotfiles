-- Shamelessly copied and adapted from https://github.com/github/awesome-copilot/blob/main/chatmodes/mentor.chatmode.md

return {
  kind = "role",
  tools = "@{file_search} @{grep_search} @{read_file} @{get_changed_files}",
  system = function()
    local path = os.getenv("XDG_CONFIG_HOME") .. "/ai/commands/mentor.md"
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
  end,
  user = function()
    return ""
  end,
}
