local constants = require("config.constants")

---Git repo/branch with caching - uses gitsigns buffer variables for performance
---@return string branch name or empty string if not in git repo
local function get_git_branch()
  local branch = vim.b.gitsigns_head
  if not branch or branch == "" then
    return ""
  end

  -- Get repo name from gitsigns status dict if available
  local gitsigns = vim.b.gitsigns_status_dict
  if gitsigns and gitsigns.root then
    -- Extract repo name from the root path
    local repo_name = vim.fn.fnamemodify(gitsigns.root, ":t")
    return repo_name .. "/" .. branch
  end

  return branch
end

---Diagnostics symbols
---@return string with diagnostic symbols and counts or empty string if no diagnostics
local function get_diagnostics()
  if not vim.diagnostic then
    return ""
  end
  local diagnostics = vim.diagnostic.get(0)
  local errors, warnings, info, hints = 0, 0, 0, 0
  for _, diagnostic in ipairs(diagnostics) do
    if diagnostic.severity == vim.diagnostic.severity.ERROR then
      errors = errors + 1
    elseif diagnostic.severity == vim.diagnostic.severity.WARN then
      warnings = warnings + 1
    elseif diagnostic.severity == vim.diagnostic.severity.INFO then
      info = info + 1
    elseif diagnostic.severity == vim.diagnostic.severity.HINT then
      hints = hints + 1
    end
  end

  local result = ""
  if errors > 0 then
    result = result .. "%#DiagnosticError# " .. constants.icons.diagnostics.error .. " " .. errors
  end
  if warnings > 0 then
    result = result .. "%#DiagnosticWarn# " .. constants.icons.diagnostics.warn .. " " .. warnings
  end
  if info > 0 then
    result = result .. "%#DiagnosticInfo# " .. constants.icons.diagnostics.info .. " " .. info
  end
  if hints > 0 then
    result = result .. "%#DiagnosticHint# " .. constants.icons.diagnostics.hint .. " " .. hints
  end

  -- reset to StatusLine for following text
  return result .. " %#StatusLine#"
end

---File icon
---@return string icon or empty string if nvim-web-devicons not available
local function get_file_icon()
  local ok, icons = pcall(require, "nvim-web-devicons")
  if not ok then
    return ""
  end
  local f = vim.fn.expand("%:t")
  local e = vim.fn.expand("%:e")
  local icon = icons.get_icon(f, e, { default = true })
  return icon and icon .. " " or ""
end

---Copilot enabled/disabled indicator
---@return string
local function get_copilot_status()
  local icon = " "
  -- TODO: coupled to copilot.lua plugin, which is not great.
  -- Must find a better way to check if copilot is enabled without depending on the plugin's internal API
  local client = package.loaded["copilot.client"]
  if type(client) ~= "table" or type(client.is_disabled) ~= "function" then
    return ""
  end

  local is_enabled = not client.is_disabled()
  if is_enabled then
    return icon
  end
  return ""
end

local M = {}
function M.build()
  local statusline = ""

  -- A: diagnostics
  local diagnostics = get_diagnostics()
  if diagnostics ~= "" then
    statusline = statusline .. diagnostics
  end
  -- right align
  statusline = statusline .. "%="

  -- X: copilot status
  statusline = statusline .. get_copilot_status() .. " "
  -- Y: filetype
  local ft = vim.bo.filetype
  if ft ~= "" then
    statusline = statusline .. get_file_icon() .. ft
  end
  -- Z: git branch
  local git_branch = get_git_branch()
  if git_branch ~= "" then
    statusline = statusline .. "  " .. git_branch .. " "
  end

  return statusline
end

vim.opt.laststatus = 3 -- global statusline
vim.opt.showmode = false -- Dont show mode since we have a statusline
vim.o.statusline = "%!v:lua.require('config.statusline').build()"

return M
