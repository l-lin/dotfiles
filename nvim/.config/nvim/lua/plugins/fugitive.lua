local M = {}

M.attach_keymaps = function()
  local map = require("mapper").map
  local bufopts = { noremap = true, silent = true }

  map("n", "<leader>gs", "<cmd>G<cr>", bufopts, "git status")
  map("n", "<leader>gc", "<cmd>G commit<cr>", bufopts, "git commit")
  map("n", "<leader>gp", "<cmd>G pull<cr>", bufopts, "git pull")
  map("n", "<leader>gP", "<cmd>G push<cr>", bufopts, "git push")
  map("n", "<leader>gF", "<cmd>G push --force-with-lease<cr>", bufopts, "git push --force-with-lease")
  map("n", "<leader>gb", "<cmd>G blame<cr>", bufopts, "git blame")
  map("n", "<leader>gl", "<cmd>0GcLog<cr>", bufopts, "git log")
end

M.setup = function()
  M.attach_keymaps()
end

return M
