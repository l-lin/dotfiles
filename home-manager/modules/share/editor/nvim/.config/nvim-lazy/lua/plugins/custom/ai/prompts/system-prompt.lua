local function get()
  local uname = vim.uv.os_uname()
  local platform = string.format(
    "sysname: %s, release: %s, machine: %s, version: %s",
    uname.sysname,
    uname.release,
    uname.machine,
    uname.version
  )

  local path = os.getenv("XDG_CONFIG_HOME") .. "/ai/system-prompt.md"
  local file = assert(io.open(path, "r"))
  local content = file:read("*a")
  file:close()
  return string.format(
    [[%s

# Environment
Here is useful information about the environment you are running in:

<environment>
- Platform: %s,
- Shell: %s,
- Current date: %s
- Current time: %s, timezone: %s(%s)
- Current working directory(git repo: %s): %s,
</environment>]],
    content,
    platform,
    vim.o.shell,
    os.date("%Y-%m-%d"),
    os.date("%H:%M:%S"),
    os.date("%Z"),
    os.date("%z"),
    vim.fn.isdirectory(".git") == 1,
    vim.fn.getcwd()
  )
end

local M = {}
M.get = get
return M
