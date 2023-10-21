-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set

-- buffer
map("n", "<F28>", "<cmd>bd<CR>", { noremap = true, silent = true, desc = "Close current buffer" })

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
map("n", "<leader>vl", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- NOTE: goto definition put here because for some reason, it's remapped to native <C-b>...
-- map("n", "<C-b>", "<cmd>Telescope lsp_definitions<cr>", { desc = "Go to definition (Ctrl+b)" })

-- do not include white space characters when using $ in visual mode, see https://vi.stackexchange.com/q/12607/15292
map("x", "$", "g_")

-- format
map({ "n", "v" }, "<M-C-L>", function()
  require("lazyvim.util").format({ force = true })
end, { desc = "Format" })
