---Execute gitbrowse with the given options.
---@param opts table|nil Options to pass to Snacks.gitbrowse
---@param yank boolean If true, yank URL to clipboard instead of opening
---@param line1 number|nil Start line for visual selection
---@param line2 number|nil End line for visual selection
local function execute_gitbrowse(opts, yank, line1, line2)
  opts = opts or {}
  if line1 and line2 then
    opts.line_start = line1
    opts.line_end = line2
  end
  if yank then
    opts.open = function(url)
      vim.fn.setreg("+", url)
    end
    opts.notify = false
  end
  Snacks.gitbrowse(opts)
  if yank then
    vim.notify("URL copied to clipboard", vim.log.levels.INFO)
  end
end

---Resolve HEAD to a full commit SHA.
---@return string|nil sha or nil if not in a git repo
local function resolve_sha()
  local sha = vim.fn.system("git rev-parse HEAD"):gsub("\n", "")
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return sha
end

---Parse owner/repo from a git remote URL.
---@param remote_url string
---@return string|nil repo name like owner/repo, or nil when unparseable
local function parse_repo_name(remote_url)
  local normalized_url = remote_url:gsub("%s+$", "")
  if normalized_url == "" then
    return nil
  end

  local repo_name = normalized_url:match("[/:]([%w%._%-]+/[%w%._%-]+)%.git$")
  if repo_name then
    return repo_name
  end

  return normalized_url:match("[/:]([%w%._%-]+/[%w%._%-]+)$")
end

---Resolve the current repository name from git origin.
---@return string|nil repo name like owner/repo, or nil if unavailable
local function get_current_repo_name()
  local remote_url = vim.fn.system("git remote get-url origin"):gsub("%s+$", "")
  if vim.v.shell_error ~= 0 or remote_url == "" then
    return nil
  end

  return parse_repo_name(remote_url)
end

---When yanking a URL for a main/master branch, prompt the user to choose between
---a branch URL (mutable) or a permalink (immutable SHA-based URL).
---@param branch_opts table|nil Options with branch key to pass to execute_gitbrowse
---@param line1 number|nil
---@param line2 number|nil
local function prompt_yank_style(branch_opts, line1, line2)
  local style_choices = {
    { label = "Branch URL (mutable)", permalink = false },
    { label = "Permalink (commit SHA)", permalink = true },
  }
  vim.ui.select(style_choices, {
    prompt = "Yank URL - Select Style",
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
      execute_gitbrowse({ branch = sha }, true, line1, line2)
    else
      execute_gitbrowse(branch_opts, true, line1, line2)
    end
  end)
end

---Returns true if the given branch exists locally or as a remote tracking branch.
---@param branch string branch name to check
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

---Browse git repository on the browser with branch selection.
---If on main/master, opens directly (or prompts for URL style when yanking).
---Otherwise prompts for branch choice first.
---@param opts { yank: boolean, visual: boolean }|nil Options: yank = copy URL, visual = called from visual mode
local function browse_with_branch_select(opts)
  opts = opts or {}
  local yank = opts.yank or false

  -- Capture visual range NOW before vim.ui.select destroys it.
  -- Only if called from visual mode (marks are set by Neovim before function call).
  local line1, line2 = nil, nil
  if opts.visual then
    local bufnr = vim.api.nvim_get_current_buf()
    local mark_start = vim.api.nvim_buf_get_mark(bufnr, "<")
    local mark_end = vim.api.nvim_buf_get_mark(bufnr, ">")
    line1 = mark_start[1]
    line2 = mark_end[1]
    -- Validate marks are set (0 means invalid/unset)
    if line1 == 0 or line2 == 0 then
      line1, line2 = nil, nil
    elseif line1 > line2 then
      line1, line2 = line2, line1
    end
  end

  local current_branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")
  if vim.v.shell_error ~= 0 then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end

  -- If already on main or master, skip branch selection.
  -- When yanking, offer permalink vs branch URL choice first.
  if current_branch == "main" or current_branch == "master" then
    if yank then
      prompt_yank_style(nil, line1, line2)
    else
      execute_gitbrowse(nil, false, line1, line2)
    end
    return
  end

  local default_branch = nil
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
    -- When yanking a main/master URL, offer permalink vs branch URL choice
    if yank and choice.is_default then
      prompt_yank_style(browse_opts, line1, line2)
    else
      execute_gitbrowse(browse_opts, yank, line1, line2)
    end
  end)
end

-- Converts a CODEOWNERS glob pattern to a Lua pattern.
-- Handles `**` (any path), `*` (any segment), `?` (any single char).
local function glob_to_lua_pattern(glob)
  local result = ""
  local i = 1
  while i <= #glob do
    local c = glob:sub(i, i)
    if c == "*" and glob:sub(i, i + 1) == "**" then
      result = result .. ".*"
      i = i + 2
    elseif c == "*" then
      result = result .. "[^/]*"
      i = i + 1
    elseif c == "?" then
      result = result .. "[^/]"
      i = i + 1
    elseif c:match("[%.%+%-%^%$%(%)%[%]%%]") then
      result = result .. "%" .. c
      i = i + 1
    else
      result = result .. c
      i = i + 1
    end
  end
  return result
end

-- Returns true if the CODEOWNERS pattern matches the given relative path.
-- Follows GitHub's gitignore-style rules:
--   - leading `/` anchors to root
--   - trailing `/` matches everything under that directory
--   - patterns without `/` match against the filename at any depth
--   - `*` matches within a path segment, `**` crosses segment boundaries
local function pattern_matches(pattern, rel_path)
  local had_leading_slash = pattern:sub(1, 1) == "/"
  local clean = pattern:gsub("^/", "")
  local is_dir = clean:sub(-1) == "/"
  if is_dir then
    clean = clean:sub(1, -2)
  end

  local has_slash = clean:find("/") ~= nil
  local anchored = had_leading_slash or has_slash
  local lua_pat = glob_to_lua_pattern(clean)
  local test = "/" .. rel_path

  if anchored then
    -- `**/foo` starts with `**/`: the `.*` in lua_pat must absorb the leading `/`,
    -- so we skip the `^/` prefix and let it match at any depth.
    local starts_with_doublestar = clean:sub(1, 3) == "**/"
    local anchor = starts_with_doublestar and "" or "^/"
    local suffix = is_dir and "/" or "$"
    if test:match(anchor .. lua_pat .. suffix) ~= nil then
      return true
    end
    -- `**` matches zero-or-more directories. When `**/` appears in the middle
    -- of a pattern (e.g. `src/**/*.rb`), the `.*` in lua_pat requires at least
    -- one path separator, so `src/foo.rb` (zero intermediate dirs) would be
    -- missed. Retry with every `**/` collapsed away to cover the zero-dir case.
    if not starts_with_doublestar and clean:find("%*%*/") then
      local zero_dir_pat = glob_to_lua_pattern(clean:gsub("%*%*/", ""))
      return test:match("^/" .. zero_dir_pat .. suffix) ~= nil
    end
    return false
  else
    -- No slash anywhere: match against the basename at any depth.
    local basename = rel_path:match("[^/]+$") or rel_path
    if is_dir then
      return test:match("/" .. lua_pat .. "/") ~= nil
    else
      return basename:match("^" .. lua_pat .. "$") ~= nil
    end
  end
end

---Find the owner for a file given raw CODEOWNERS content.
---Last matching rule wins, mirroring GitHub semantics.
---@param content string raw content of a CODEOWNERS file
---@param rel_path string file path relative to the repository root
---@return string owner(s) string, or "" if none matched
local function find_owner(content, rel_path)
  local matched = ""
  for raw_line in content:gmatch("[^\n]+") do
    local line = raw_line:match("^%s*(.-)%s*$")
    if line ~= "" and line:sub(1, 1) ~= "#" then
      -- Extract pattern and owners separately: a line with no owners intentionally
      -- clears ownership (GitHub semantics), so we must not skip it.
      local pattern = line:match("^(%S+)")
      local owners = line:match("^%S+%s+(.*)")
      if pattern and pattern_matches(pattern, rel_path) then
        matched = owners or ""
      end
    end
  end
  return matched
end

---Lualine component: shows the CODEOWNERS entry for the current buffer.
---Returns "" when the buffer has no file, no git root, or no matching rule.
local function codeowner()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" then
    return ""
  end
  local bufnr = vim.api.nvim_get_current_buf()

  local root = vim.fs.root(bufnr, { ".git" }) or vim.fn.getcwd()
  local rel_path = vim.fn.fnamemodify(bufname, ":p"):sub(#root + 2)

  local f = io.open(root .. "/CODEOWNERS", "r")
  if not f then
    return ""
  end

  local content = f:read("*a")
  f:close()

  return find_owner(content, rel_path)
end

local M = {}
M.browse_with_branch_select = browse_with_branch_select
M.get_current_repo_name = get_current_repo_name
M.find_owner = find_owner
M.codeowner = codeowner
return M
