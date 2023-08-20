-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<F28>", "<cmd>bd<CR>", { noremap = true, silent = true, desc = "Close current buffer" })

-- navigation
vim.keymap.set("n", "<F12>", "<cmd>bn<CR>", { noremap = true, silent = true, desc = "Next buffer" })
vim.keymap.set("n", "<F24>", "<cmd>bp<CR>", { noremap = true, silent = true, desc = "Previous buffer (Shift+F12)" })

-- editing
vim.keymap.set("n", "<C-y>", "dd", { noremap = true, desc = "Delete line" })

-- use different buffer for delete and paste
vim.keymap.set("n", "d", '"_d', { noremap = true })
vim.keymap.set("v", "d", '"_d', { noremap = true })
vim.keymap.set("v", "p", '"_dP', { noremap = true })

-- go to first character in line (need to stretch my left hand to type ^)
vim.keymap.set("x", "0", "^")
vim.keymap.set("n", "0", "^")
