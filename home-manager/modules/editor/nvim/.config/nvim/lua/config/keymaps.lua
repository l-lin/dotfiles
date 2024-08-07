-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set

-- buffer
-- Same behavior as browsers (muscle memory).
map("n", "<F28>", "<cmd>bd<CR>", { noremap = true, silent = true, desc = "Close current buffer (Ctrl+F4)" })

-- navigation
-- Always put cursor at middle of screen.
map("n", "<C-d>", "<C-d>zz", { noremap = true })
map("n", "<C-u>", "<C-u>zz", { noremap = true })

-- search
-- Always put cursor at middle of screen.
map("n", "n", "nzzzv", { noremap = true })
map("n", "N", "Nzzzv", { noremap = true })

-- tab
map("n", "]<tab>", "<cmd>tabnext<cr>", { noremap = true, desc = "Next Tab" })
map("n", "[<tab>", "<cmd>tabprevious<cr>", { noremap = true, desc = "Previous Tab" })

-- editing
map("n", "<C-y>", "dd", { noremap = true, desc = "Delete line" })

-- use different buffer for delete and paste
map("n", "d", '"_d', { noremap = true })
map("v", "d", '"_d', { noremap = true })
map("v", "p", '"_dP', { noremap = true })

-- documentation
vim.cmd([[ command CheatSheet split $HOME/.config/nvim/doc/cheat_sheet.txt ]])

-- Diagnostics
-- Same behavior as IntelliJ.
map("n", "<F25>", vim.diagnostic.open_float, { desc = "Line Diagnostics (Ctrl+F1)" })
map("n", "<F2>", vim.diagnostic.goto_next, { desc = "Next diagnostic (F2)" })

-- do not include white space characters when using $ in visual mode, see https://vi.stackexchange.com/q/12607/15292
map("x", "$", "g_")

-- format
map({ "n", "v" }, "<M-C-L>", function()
  require("lazyvim.util").format({ force = true })
end, { desc = "Format" })
