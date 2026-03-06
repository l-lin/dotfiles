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
    Snacks.gitbrowse(opts)
    vim.notify("URL copied to clipboard", vim.log.levels.INFO)
  else
    Snacks.gitbrowse(opts)
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

---Browse git repository on the browser with branch selection.
---If on main/master, opens directly (or prompts for URL style when yanking).
---Otherwise prompts for branch choice first.
---@param opts { yank: boolean, visual: boolean }|nil Options: yank = copy URL, visual = called from visual mode
local function browse_with_branch_select(opts)
  opts = opts or {}
  local yank = opts.yank or false

  -- Capture visual range NOW before vim.ui.select destroys it
  -- Only if called from visual mode (marks are set by Neovim before function call)
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

  -- Get current branch name
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

  -- Check which default branch exists (main or master)
  local has_main = vim.fn.system("git show-ref --verify --quiet refs/heads/main && echo 1 || echo 0"):gsub("\n", "")
    == "1"
  local has_remote_main = vim.fn
    .system("git show-ref --verify --quiet refs/remotes/origin/main && echo 1 || echo 0")
    :gsub("\n", "") == "1"
  local has_master = vim.fn.system("git show-ref --verify --quiet refs/heads/master && echo 1 || echo 0"):gsub("\n", "")
    == "1"
  local has_remote_master = vim.fn
    .system("git show-ref --verify --quiet refs/remotes/origin/master && echo 1 || echo 0")
    :gsub("\n", "") == "1"

  local default_branch = nil
  if has_main or has_remote_main then
    default_branch = "main"
  elseif has_master or has_remote_master then
    default_branch = "master"
  end

  -- Build choices
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

local M = {}
M.browse_with_branch_select = browse_with_branch_select
return M
