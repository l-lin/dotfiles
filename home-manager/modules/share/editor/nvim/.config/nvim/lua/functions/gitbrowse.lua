---
--- Copy of https://github.com/folke/snacks.nvim/blob/882c996cf28183f4d63640de0b4c02ec886d01f2/lua/snacks/gitbrowse.lua
--- with some changes:
--- - use native nvim functions instead of snacks
--- - open without line numbers
--- - support yank
---

---@alias dotfiles.gitbrowse.What "repo"|"branch"|"file"|"commit"|"permalink"

---@class dotfiles.gitbrowse.Fields
---@field branch? string
---@field file? string
---@field line_start? number
---@field line_end? number
---@field commit? string

---@alias dotfiles.gitbrowse.UrlPattern string|fun(fields: dotfiles.gitbrowse.Fields): string

---@class dotfiles.gitbrowse.Remote
---@field name string
---@field url string

---@class dotfiles.gitbrowse.Config
---@field notify? boolean
---@field yank? boolean
---@field open? fun(url: string)
---@field what? dotfiles.gitbrowse.What
---@field commit? string
---@field branch? string
---@field line_start? number
---@field line_end? number
---@field remote_patterns? string[][]
---@field url_patterns? table<string, table<dotfiles.gitbrowse.What, dotfiles.gitbrowse.UrlPattern>>

---@class dotfiles.gitbrowse.BrowseWithBranchSelectOpts
---@field yank? boolean
---@field visual? boolean

local uv = vim.uv or vim.loop

---@param prefix string
---@param fields dotfiles.gitbrowse.Fields
---@return string
local function with_line_fragment(prefix, fields)
  if not (fields.line_start and fields.line_end) then
    return ""
  end
  return prefix:format(fields.line_start, fields.line_end)
end

---@type dotfiles.gitbrowse.Config
local defaults = {
  notify = true,
  yank = false,
  open = function(url)
    if vim.ui and vim.ui.open then
      vim.ui.open(url)
      return
    end
    vim.fn.system({ "open", url })
  end,
  what = "commit",
  commit = nil,
  branch = nil,
  line_start = nil,
  line_end = nil,
  remote_patterns = {
    { "^(https?://.*)%.git$", "%1" },
    { "^git@(.+):(.+)%.git$", "https://%1/%2" },
    { "^git@(.+):(.+)$", "https://%1/%2" },
    { "^git@(.+)/(.+)$", "https://%1/%2" },
    { "^org%-%d+@(.+):(.+)%.git$", "https://%1/%2" },
    { "^ssh://git@(.*)$", "https://%1" },
    { "^ssh://([^:/]+)(:%d+)/(.*)$", "https://%1/%3" },
    { "^ssh://([^/]+)/(.*)$", "https://%1/%2" },
    { "ssh%.dev%.azure%.com/v3/(.*)/(.*)$", "dev.azure.com/%1/_git/%2" },
    { "^https://%w*@(.*)", "https://%1" },
    { "^git@(.*)", "https://%1" },
    { ":%d+", "" },
    { "%.git$", "" },
  },
  url_patterns = {
    ["github%.com"] = {
      branch = "/tree/{branch}",
      file = function(fields)
        return "/blob/" .. fields.branch .. "/" .. fields.file .. with_line_fragment("#L%d-L%d", fields)
      end,
      permalink = function(fields)
        return "/blob/" .. fields.commit .. "/" .. fields.file .. with_line_fragment("#L%d-L%d", fields)
      end,
      commit = "/commit/{commit}",
    },
    ["gitlab%.com"] = {
      branch = "/-/tree/{branch}",
      file = function(fields)
        return "/-/blob/" .. fields.branch .. "/" .. fields.file .. with_line_fragment("#L%d-%d", fields)
      end,
      permalink = function(fields)
        return "/-/blob/" .. fields.commit .. "/" .. fields.file .. with_line_fragment("#L%d-%d", fields)
      end,
      commit = "/-/commit/{commit}",
    },
    ["bitbucket%.org"] = {
      branch = "/src/{branch}",
      file = function(fields)
        return "/src/" .. fields.branch .. "/" .. fields.file .. with_line_fragment("#lines-%d-L%d", fields)
      end,
      permalink = function(fields)
        return "/src/" .. fields.commit .. "/" .. fields.file .. with_line_fragment("#lines-%d-L%d", fields)
      end,
      commit = "/commits/{commit}",
    },
    ["git.sr.ht"] = {
      branch = "/tree/{branch}",
      file = "/tree/{branch}/item/{file}",
      permalink = function(fields)
        local line_fragment = fields.line_start and ("#L%d"):format(fields.line_start) or ""
        return "/tree/" .. fields.commit .. "/item/" .. fields.file .. line_fragment
      end,
      commit = "/commit/{commit}",
    },
  },
}

local open_gitbrowse

---@param opts? dotfiles.gitbrowse.Config
---@return dotfiles.gitbrowse.Config
local function get_config(opts)
  return vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

---@param message string
---@param details? string
local function notify_error(message, details)
  local lines = { message }
  if details and details ~= "" then
    table.insert(lines, details)
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.ERROR, { title = "Git Browse" })
end

---@param command string[]
---@param error_message string
---@return string[]
local function system(command, error_message)
  local output = vim.fn.system(command)
  if vim.v.shell_error ~= 0 then
    notify_error(error_message, output)
    error("__gitbrowse__")
  end
  return vim.split(vim.trim(output), "\n", { trimempty = true })
end

---@param hash string
---@param cwd string
---@return boolean
local function is_valid_commit_hash(hash, cwd)
  if not (hash:match("^[a-fA-F0-9]+$") and #hash >= 7) then
    return false
  end
  system({ "git", "-C", cwd, "rev-parse", "--verify", hash }, "Invalid commit hash")
  return true
end

---@return string|nil
local function resolve_sha()
  local sha = vim.fn.system("git rev-parse HEAD"):gsub("\n", "")
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return sha
end

---@param branch string
---@return boolean
local function branch_exists(branch)
  local local_ref = vim.fn.system("git show-ref --verify --quiet refs/heads/" .. branch .. " && echo 1 || echo 0")
  if local_ref:gsub("\n", "") == "1" then
    return true
  end
  local remote_ref =
    vim.fn.system("git show-ref --verify --quiet refs/remotes/origin/" .. branch .. " && echo 1 || echo 0")
  return remote_ref:gsub("\n", "") == "1"
end

---@param opts dotfiles.gitbrowse.Config|nil
---@param yank boolean
---@param line_start number|nil
---@param line_end number|nil
local function execute_gitbrowse(opts, yank, line_start, line_end)
  opts = opts or {}
  if line_start and line_end then
    opts.line_start = line_start
    opts.line_end = line_end
  end
  opts.yank = yank
  open_gitbrowse(opts)
end

---@param branch_opts dotfiles.gitbrowse.Config|nil
---@param yank boolean
---@param line_start number|nil
---@param line_end number|nil
local function prompt_branch_style(branch_opts, yank, line_start, line_end)
  local style_choices = {
    { label = "Branch URL (mutable)", permalink = false },
    { label = "Permalink (commit SHA)", permalink = true },
  }
  vim.ui.select(style_choices, {
    prompt = "Select Style",
    format_item = function(item)
      return item.label
    end,
  }, function(style)
    if not style then
      return
    end
    if style.permalink then
      local sha = resolve_sha()
      if not sha then
        vim.notify("Not in a git repository", vim.log.levels.ERROR)
        return
      end
      execute_gitbrowse({ branch = sha }, yank, line_start, line_end)
      return
    end
    execute_gitbrowse(branch_opts, yank, line_start, line_end)
  end)
end

---@param url string
---@param opts? dotfiles.gitbrowse.Config
local function handle_url(url, opts)
  local config = get_config(opts)
  if config.yank then
    vim.fn.setreg("+", url)
    if config.notify ~= false then
      vim.notify("URL copied to clipboard", vim.log.levels.INFO, { title = "Git Browse" })
    end
    return
  end
  if config.notify ~= false then
    vim.notify(("Opening %s"):format(url), vim.log.levels.INFO, { title = "Git Browse" })
  end
  config.open(url)
end

---@param remote string
---@param opts? dotfiles.gitbrowse.Config
---@return string
local function get_repo(remote, opts)
  local config = get_config(opts)
  local repo = remote
  for _, pattern in ipairs(config.remote_patterns) do
    repo = repo:gsub(pattern[1], pattern[2])
  end
  if repo:find("https://") == 1 then
    return repo
  end
  return ("https://%s"):format(repo)
end

---@param repo string
---@param fields dotfiles.gitbrowse.Fields
---@param opts? dotfiles.gitbrowse.Config
---@return string
local function get_url(repo, fields, opts)
  local config = get_config(opts)
  for remote, patterns in pairs(config.url_patterns) do
    if repo:find(remote) then
      local pattern = patterns[config.what]
      if type(pattern) == "string" then
        return repo .. pattern:gsub("(%b{})", function(key)
          return fields[key:sub(2, -2)] or ""
        end)
      end
      if type(pattern) == "function" then
        return repo .. pattern(fields)
      end
    end
  end
  return repo
end

---@param opts? dotfiles.gitbrowse.Config
local function open_gitbrowse_impl(opts)
  local config = get_config(opts)
  local file = vim.api.nvim_buf_get_name(0) ---@type string?
  file = file and (uv.fs_stat(file) or {}).type == "file" and vim.fs.normalize(file) or nil
  local cwd = file and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd()

  ---@type dotfiles.gitbrowse.Fields
  local fields = {
    branch = config.branch
      or system({ "git", "-C", cwd, "rev-parse", "--abbrev-ref", "HEAD" }, "Failed to get current branch")[1],
    file = file and system({ "git", "-C", cwd, "ls-files", "--full-name", file }, "Failed to get git file path")[1],
    line_start = config.line_start,
    line_end = config.line_end,
    commit = config.commit,
  }

  if not fields.commit then
    if config.what == "permalink" then
      fields.commit = system(
        { "git", "-C", cwd, "log", "-n", "1", "--pretty=format:%H", "--", file },
        "Failed to get latest commit of file"
      )[1]
    else
      local word_under_cursor = vim.fn.expand("<cword>")
      fields.commit = is_valid_commit_hash(word_under_cursor, cwd) and word_under_cursor or nil
    end
  end

  if not fields.commit and (config.what == "commit" or config.what == "permalink") then
    config.what = "file"
  end
  if not fields.commit and not fields.file then
    config.what = "branch"
  end
  if not fields.commit and not fields.branch then
    config.what = "repo"
  end

  ---@type dotfiles.gitbrowse.Remote[]
  local remotes = {}
  for _, line in ipairs(system({ "git", "-C", cwd, "remote", "-v" }, "Failed to get git remotes")) do
    local name, remote = line:match("(%S+)%s+(%S+)%s+%(fetch%)")
    if name and remote then
      local repo = get_repo(remote, config)
      table.insert(remotes, {
        name = name,
        url = get_url(repo, fields, config),
      })
    end
  end

  local function open_remote(remote)
    if not remote then
      return
    end
    handle_url(remote.url, config)
  end

  if #remotes == 0 then
    notify_error("No git remotes found")
    return
  end
  if #remotes == 1 then
    open_remote(remotes[1])
    return
  end

  vim.ui.select(remotes, {
    prompt = "Select remote to browse",
    format_item = function(item)
      return item.name .. (" "):rep(math.max(0, 8 - #item.name)) .. " 🔗 " .. item.url
    end,
  }, open_remote)
end

open_gitbrowse = function(opts)
  local ok, err = pcall(open_gitbrowse_impl, opts)
  if not ok and err ~= "__gitbrowse__" then
    error(err)
  end
end

---@param opts? dotfiles.gitbrowse.BrowseWithBranchSelectOpts
local function browse_with_branch_select(opts)
  opts = opts or {}
  local yank = opts.yank or false

  local line_start, line_end = nil, nil
  if opts.visual then
    local bufnr = vim.api.nvim_get_current_buf()
    local mark_start = vim.api.nvim_buf_get_mark(bufnr, "<")
    local mark_end = vim.api.nvim_buf_get_mark(bufnr, ">")
    line_start = mark_start[1]
    line_end = mark_end[1]
    if line_start == 0 or line_end == 0 then
      line_start, line_end = nil, nil
    elseif line_start > line_end then
      line_start, line_end = line_end, line_start
    end
  end

  local current_branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")
  if vim.v.shell_error ~= 0 then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end

  if current_branch == "main" or current_branch == "master" then
    prompt_branch_style(nil, yank, line_start, line_end)
    return
  end

  local default_branch
  if branch_exists("main") then
    default_branch = "main"
  elseif branch_exists("master") then
    default_branch = "master"
  end

  local choices = { { label = "Current Branch (" .. current_branch .. ")", branch = nil, is_default = false } }
  if default_branch then
    table.insert(choices, {
      label = default_branch:sub(1, 1):upper() .. default_branch:sub(2) .. " Branch",
      branch = default_branch,
      is_default = true,
    })
  end

  local action = yank and "Yank" or "Open"
  vim.ui.select(choices, {
    prompt = action .. " Git URL - Select Branch",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    local browse_opts = choice.branch and { branch = choice.branch } or nil
    prompt_branch_style(browse_opts, yank, line_start, line_end)
  end)
end

local M = {}
M.browse_with_branch_select = browse_with_branch_select
return M
