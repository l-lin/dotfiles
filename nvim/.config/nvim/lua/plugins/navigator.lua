local M = {}

M.attach_keymaps = function()
  local map = require("mapper").map
  local bufopts = { noremap = true, silent = true }

  map({ "n", "t" }, "<C-h>", "<cmd>NavigatorLeft<cr>", bufopts, "Navigate left")
  map({ "n", "t" }, "<C-l>", "<cmd>NavigatorRight<cr>", bufopts, "Navigate right")
  map({ "n", "t" }, "<C-k>", "<cmd>NavigatorUp<cr>", bufopts, "Navigate up")
  map({ "n", "t" }, "<C-j>", "<cmd>NavigatorDown<cr>", bufopts, "Navigate down")
  -- map({ "n", "t" }, "<C-\\>", "<cmd>NavigatorPrevious<cr>", bufopts, "Navigate previous")
end

M.setup = function()
  require("Navigator").setup()

  M.attach_keymaps()
end

return M
