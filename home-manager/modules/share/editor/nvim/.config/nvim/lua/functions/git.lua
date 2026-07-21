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

---Extract repo name and PR id from a pull request URL.
---@param input_url string
---@return string|nil repo_name repo name like owner/repo, or nil when unparseable
---@return number|nil pr_id pull request id, or nil when unparseable
local function extract_repo_name_and_pr_id_from_url(input_url)
  local normalized_url = input_url:gsub("%s+$", "")

  local repo_name, pr_id = normalized_url:match("^https?://[^/]+/([%w%._%-]+/[%w%._%-]+)/pull/(%d+)$")
  if repo_name and pr_id then
    return repo_name, tonumber(pr_id)
  end

  repo_name, pr_id = normalized_url:match("^https?://[^/]+/([%w%._%-]+/[%w%._%-]+)/pull/(%d+)[/?#].*$")
  if repo_name and pr_id then
    return repo_name, tonumber(pr_id)
  end

  return nil, nil
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

---@param nul_output string
---@return string[]
local function split_nul_output(nul_output)
  if nul_output == "" then
    return {}
  end

  local paths = {}
  local start_index = 1

  while true do
    local separator_index = nul_output:find("\0", start_index, true)
    if separator_index == nil then
      break
    end

    table.insert(paths, nul_output:sub(start_index, separator_index - 1))
    start_index = separator_index + 1
  end

  return paths
end

---@param staged_output string
---@param unstaged_output string
---@param untracked_output string
---@return string[]
local function list_changed_files(staged_output, unstaged_output, untracked_output)
  local changed_file_lookup = {}

  for _, output in ipairs({ staged_output, unstaged_output, untracked_output }) do
    for _, path in ipairs(split_nul_output(output)) do
      changed_file_lookup[path] = true
    end
  end

  local changed_files = {}
  for path in pairs(changed_file_lookup) do
    table.insert(changed_files, path)
  end

  table.sort(changed_files)
  return changed_files
end

---@param changed_files string[]
---@param current_relative_path string|nil
---@param direction "next"|"prev"
---@return string|nil
local function find_changed_file_target(changed_files, current_relative_path, direction)
  if #changed_files == 0 then
    return nil
  end

  if current_relative_path == nil or current_relative_path == "" then
    return direction == "next" and changed_files[1] or changed_files[#changed_files]
  end

  if direction == "next" then
    for _, path in ipairs(changed_files) do
      if path > current_relative_path then
        return path
      end
    end

    return changed_files[1]
  end

  for index = #changed_files, 1, -1 do
    if changed_files[index] < current_relative_path then
      return changed_files[index]
    end
  end

  return changed_files[#changed_files]
end

---@return string|nil
local function get_current_repo_root()
  local current_buffer_path = vim.api.nvim_buf_get_name(0)
  local start_directory = current_buffer_path ~= "" and vim.fn.fnamemodify(current_buffer_path, ":p:h")
    or vim.fn.getcwd()
  local system_result = vim
    .system({ "git", "rev-parse", "--show-toplevel" }, { cwd = start_directory, text = true })
    :wait()

  if system_result.code ~= 0 then
    return nil
  end

  return system_result.stdout:gsub("%s+$", "")
end

---@param repo_root string
---@return string[]
local function get_repo_changed_files(repo_root)
  local staged_result = vim
    .system({ "git", "diff", "--name-only", "--cached", "-z" }, { cwd = repo_root, text = true })
    :wait()
  local unstaged_result = vim.system({ "git", "diff", "--name-only", "-z" }, { cwd = repo_root, text = true }):wait()
  local untracked_result = vim
    .system({ "git", "ls-files", "--others", "--exclude-standard", "-z" }, { cwd = repo_root, text = true })
    :wait()

  return list_changed_files(staged_result.stdout, unstaged_result.stdout, untracked_result.stdout)
end

---@param repo_root string
---@return string|nil
local function get_current_relative_path(repo_root)
  local current_buffer_path = vim.api.nvim_buf_get_name(0)
  if current_buffer_path == "" then
    return nil
  end

  local absolute_buffer_path = vim.fn.fnamemodify(current_buffer_path, ":p")
  local repo_prefix = repo_root .. "/"
  if absolute_buffer_path:sub(1, #repo_prefix) ~= repo_prefix then
    return nil
  end

  return absolute_buffer_path:sub(#repo_prefix + 1)
end

---@param repo_root string
---@param relative_path string
local function open_changed_file(repo_root, relative_path)
  local absolute_path = repo_root .. "/" .. relative_path
  if vim.fn.filereadable(absolute_path) == 1 then
    vim.cmd.edit(vim.fn.fnameescape(absolute_path))
    return
  end

  vim.cmd("Git --paginate show HEAD:" .. vim.fn.fnameescape(relative_path))
end

---@param direction "next"|"prev"
local function navigate_changed_file(direction)
  -- AI: use synchronous git calls here; this mapping runs on demand and the repo-wide path list is tiny.
  local repo_root = get_current_repo_root()
  if repo_root == nil then
    vim.notify("Not in a Git repository", vim.log.levels.WARN)
    return
  end

  local changed_files = get_repo_changed_files(repo_root)
  local target_relative_path = find_changed_file_target(changed_files, get_current_relative_path(repo_root), direction)
  if target_relative_path == nil then
    vim.notify("No changed files", vim.log.levels.INFO)
    return
  end

  open_changed_file(repo_root, target_relative_path)
end

local M = {}
M.get_current_repo_name = get_current_repo_name
M.extract_repo_name_and_pr_id_from_url = extract_repo_name_and_pr_id_from_url
M.find_owner = find_owner
M.codeowner = codeowner
M.navigate_changed_file = navigate_changed_file
return M
