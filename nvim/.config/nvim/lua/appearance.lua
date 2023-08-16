local M = {}

M.get_background_color = function()
  local normal_color = vim.api.nvim_get_hl_by_name("Normal", true)
  return normal_color.background
end

M.setup = function()
  -- theme
  vim.o.bg = "dark"
  vim.o.termguicolors = true

  vim.o.syntax = "on"

  -- misc
  vim.o.number = true    -- show line numbers
  vim.o.cursorline = true -- highlight line
  vim.o.signcolumn = "yes" -- always show the signcolum
  vim.o.cmdheight = 2    -- give more space for displaying messages
end

return M
