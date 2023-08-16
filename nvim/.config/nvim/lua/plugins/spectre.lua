local M = {}

M.attach_keymaps = function()
  local map = require("mapper").map
  local bufopts = { noremap = true, silent = true }

  map({ "n", "v" }, "<leader>rr", "<cmd>lua require('spectre').open()<cr>", bufopts, "Spectre open search and replace")
  map("v", "<leader>rw", "<cmd>lua require('spectre').open_visual({select_word=true})<CR>", bufopts,
    "Spectre open visual search and replace word")

  map("n", "<A-r>", "<cmd>lua require('spectre').open_file_search()<cr>", bufopts,
    "Spectre open search and replace in file (Alt+r)")
  map("n", "<leader>rf", "<cmd>lua require('spectre').open_file_search()<cr>", bufopts,
    "Spectre open search and replace in file")
end

M.setup = function()
  M.attach_keymaps()
end

return M
