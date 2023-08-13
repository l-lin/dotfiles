local leap_fn = function()
  local current_window = vim.fn.win_getid()
  require("leap").leap { target_windows = { current_window } }
end

vim.keymap.set("n", "<leader>nl", leap_fn , { noremap = true, silent = true, desc = "Leap to" })
vim.keymap.set("n", "<C-\\>", leap_fn , { noremap = true, silent = true, desc = "Leap to" })
