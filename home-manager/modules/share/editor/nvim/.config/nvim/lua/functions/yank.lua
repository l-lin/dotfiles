local function yank_relative_path()
  vim.fn.setreg("+", vim.fn.expand("%:."))
end

local function yank_absolute_path()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
end

local function yank_filename()
  vim.fn.setreg("+", vim.fn.expand("%:t"))
end

local function line_range()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  if start_line == end_line then
    return tostring(start_line)
  end
  return tostring(start_line) .. "-" .. tostring(end_line)
end

local function yank_relative_path_with_line_range()
  vim.fn.setreg("+", vim.fn.expand("%:.") .. ":" .. line_range())
end

local function yank_absolute_path_with_line_range()
  vim.fn.setreg("+", vim.fn.expand("%:p") .. ":" .. line_range())
end

local M = {}
M.yank_relative_path = yank_relative_path
M.yank_absolute_path = yank_absolute_path
M.yank_filename = yank_filename
M.yank_relative_path_with_line_range = yank_relative_path_with_line_range
M.yank_absolute_path_with_line_range = yank_absolute_path_with_line_range
return M
