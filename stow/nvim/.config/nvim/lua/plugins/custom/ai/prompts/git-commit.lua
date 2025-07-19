return {
  kind = "action",
  tools = "@{cmd_runner} @{get_changed_files}",
  system = function()
    local path = os.getenv("XDG_CONFIG_HOME") .. "/ai/prompts/git-commit.md"
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
  end,
  user = function()
    return "Generate a git commit message"
  end,
}
