-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set

-- buffer
map("n", "<F28>", "<cmd>bd<CR>", { noremap = true, silent = true, desc = "Close current buffer" })

-- tab
map("n", "]<tab>", "<cmd>tabnext<cr>", { noremap = true, desc = "Next Tab" })
map("n", "[<tab>", "<cmd>tabprevious<cr>", { noremap = true, desc = "Previous Tab" })

-- editing
map("n", "<C-y>", "dd", { noremap = true, desc = "Delete line" })

-- use different buffer for delete and paste
map("n", "d", '"_d', { noremap = true })
map("v", "d", '"_d', { noremap = true })
map("v", "p", '"_dP', { noremap = true })

-- go to first character in line (need to stretch my left hand to type ^)
map("x", "0", "^")
map("n", "0", "^")

-- documentation
vim.cmd([[ command CheatSheet split $HOME/.config/nvim/doc/cheat_sheet.txt]])

-- lazy
vim.keymap.del("n", "<leader>l")
map("n", "<leader>vl", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- Diagnostics
map("n", "<F25>", vim.diagnostic.open_float, { desc = "Line Diagnostics (Ctrl+F1)" })
map("n", "<F2>", vim.diagnostic.goto_next, { desc = "Next diagnostic (F2)" })

-- do not include white space characters when using $ in visual mode, see https://vi.stackexchange.com/q/12607/15292
map("x", "$", "g_")

-- format
map({ "n", "v" }, "<M-C-L>", function()
  require("lazyvim.util").format({ force = true })
end, { desc = "Format" })

-- select all
map("n", "<C-a>", "gg<S-v>G", { noremap = true, desc = "Select all" })
