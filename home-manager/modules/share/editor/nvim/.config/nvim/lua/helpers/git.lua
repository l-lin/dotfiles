---Browse git repository on the browser with branch selection.
---If on main/master, opens directly. Otherwise prompts for branch choice.
local function browse_with_branch_select()
  -- Get current branch name
  local current_branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")
  if vim.v.shell_error ~= 0 then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end

  -- If already on main or master, just open directly
  if current_branch == "main" or current_branch == "master" then
    Snacks.gitbrowse()
    return
  end

  -- Check which default branch exists (main or master)
  local has_main = vim.fn.system("git show-ref --verify --quiet refs/heads/main && echo 1 || echo 0"):gsub("\n", "") == "1"
  local has_remote_main = vim.fn.system("git show-ref --verify --quiet refs/remotes/origin/main && echo 1 || echo 0"):gsub("\n", "") == "1"
  local has_master = vim.fn.system("git show-ref --verify --quiet refs/heads/master && echo 1 || echo 0"):gsub("\n", "") == "1"
  local has_remote_master = vim.fn.system("git show-ref --verify --quiet refs/remotes/origin/master && echo 1 || echo 0"):gsub("\n", "") == "1"

  local default_branch = nil
  if has_main or has_remote_main then
    default_branch = "main"
  elseif has_master or has_remote_master then
    default_branch = "master"
  end

  -- Build choices
  local choices = { { label = "Current Branch (" .. current_branch .. ")", branch = nil } }
  if default_branch then
    table.insert(choices, { label = default_branch:sub(1, 1):upper() .. default_branch:sub(2) .. " Branch", branch = default_branch })
  end

  vim.ui.select(choices, {
    prompt = "Open Git Repository on Browser - Select Branch",
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then return end
    if choice.branch then
      Snacks.gitbrowse({ branch = choice.branch })
    else
      Snacks.gitbrowse()
    end
  end)
end

local M = {}
M.browse_with_branch_select = browse_with_branch_select
return M
