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

local M = {}
M.get_current_repo_name = get_current_repo_name
M.extract_repo_name_and_pr_id_from_url = extract_repo_name_and_pr_id_from_url
M.find_owner = find_owner
M.codeowner = codeowner
return M
