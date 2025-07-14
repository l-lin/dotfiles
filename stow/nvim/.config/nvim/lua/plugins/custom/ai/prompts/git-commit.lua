return {
  kind = "action",
  tools = "@{cmd_runner}",
  system = function()
    local path = os.getenv("XDG_CONFIG_HOME") .. "/ai/commands/git-commit.md"
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
  end,
  user = function()
    return string.format(
      [[Given the git diff listed below, please generate a commit message for me:

```diff
%s
```
]],
      vim.fn.system("git diff --no-ext-diff --staged")
    )
  end,
}
