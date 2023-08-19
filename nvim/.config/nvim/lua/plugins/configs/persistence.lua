local M = {}

M.attach_keymaps = function()
  local map = require("mapper").map
  local bufopts = { noremap = true, silent = true }

  map("n", "<leader>ss", "<CMD>lua require('persistence').load()<CR>", bufopts, "Restore session for current directory")
  map("n", "<leader>sl", "<CMD>lua require('persistence').load({ last = true})<CR>", bufopts, "Restore last session")
  map("n", "<leader>sd", "<CMD>lua require('persistence').stop()<CR>", bufopts, "Stop persistence")
end

M.setup = function()
  require("persistence").setup()

  M.attach_keymaps()
end

return M
