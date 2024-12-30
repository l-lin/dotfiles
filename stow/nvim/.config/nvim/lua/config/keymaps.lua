-- Keymaps are automatically loaded on the VeryLazy event.
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua.
-- Add any additional keymaps here.

---Put the cursor in the middle of the screen, only when navigating with count.
---No need to move the whole screen when moving line by line.
---@param key string either 'j' or 'k'
local function cursor_to_middle_of_screen(key)
  if vim.v.count > 1 then
    vim.api.nvim_command("norm! " .. vim.v.count .. key .. "zz")
  else
    vim.api.nvim_command("norm! " .. key)
  end
end

---Remove the trailing whitespace when joining line if the last character is a
---open parenthesis.
local function remove_trailing_whitespace()
  local last_char = string.sub(vim.api.nvim_get_current_line(), -1, -1)
  if last_char == "(" then
    vim.api.nvim_command("norm! Jx")
  else
    vim.api.nvim_command("norm! J")
  end
end

local map = vim.keymap.set

-- buffer
-- Same behavior as browsers (muscle memory).
map("n", "<F28>", "<cmd>bd<CR>", { noremap = true, silent = true, desc = "Close current buffer (Ctrl+F4)" })

-- yank file path / name
map("n", "<leader>yf", "<cmd>let @+=expand('%:.')<CR>", { noremap = true, desc = "Copy current buffer relative path to clipboard" })
map("n", "<leader>yF", "<cmd>let @+=expand('%:p')<CR>", { noremap = true, desc = "Copy current buffer absolute path to clipboard" })
map("n", "<leader>yn", "<cmd>let @+=expand('%:t')<CR>", { noremap = true, desc = "Copy current buffer file name to clipboard" })

-- remove keymaps set globally by LazyVim
-- use default H and L to navigate
vim.keymap.del("n", "<S-h>")
vim.keymap.del("n", "<S-l>")

-- navigation
-- Always put cursor at middle of screen.
map("n", "<C-d>", "<C-d>zz", { noremap = true })
map("n", "<C-u>", "<C-u>zz", { noremap = true })
map("n", "<S-h>", "<S-h>zz", { noremap = true })
map("n", "<S-l>", "<S-l>zz", { noremap = true })
map("n", "{", "{zz", { noremap = true })
map("n", "}", "}zz", { noremap = true })
map("n", "j", function() cursor_to_middle_of_screen("j") end, { noremap = true })
map("n", "k", function() cursor_to_middle_of_screen("k") end, { noremap = true })
-- search
map("n", "n", "nzzzv", { noremap = true })
map("n", "N", "Nzzzv", { noremap = true })

-- tab
map("n", "]<tab>", "<cmd>tabnext<cr>", { noremap = true, desc = "Next Tab" })
map("n", "[<tab>", "<cmd>tabprevious<cr>", { noremap = true, desc = "Previous Tab" })

-- editing (same behavior as Intellij)
map("n", "<C-y>", "dd", { noremap = true, desc = "Delete line" })

-- use different buffer for delete and paste
-- Disabling because pressing `d` or `p` when filling snippets is annoying.
-- map("n", "d", '"_d', { noremap = true })
-- map("v", "d", '"_d', { noremap = true })
-- map("v", "p", '"_dP', { noremap = true })

-- documentation
vim.api.nvim_create_user_command('CheatSheet', function()
  vim.cmd('split ' .. vim.fn.expand(vim.fn.stdpath("config") .. '/doc/cheat_sheet.txt'))
end, {})

-- diagnostics (same behavior as IntelliJ)
map("n", "<F25>", vim.diagnostic.open_float, { desc = "Line Diagnostics (Ctrl+F1)" })
map("n", "<F2>", vim.diagnostic.goto_next, { desc = "Next diagnostic (F2)" })

-- do not include white space characters when using $ in visual mode, see https://vi.stackexchange.com/q/12607/15292
map("x", "$", "g_")

-- format
map({ "n", "v" }, "<M-C-L>", function() require("lazyvim.util").format({ force = true }) end, { desc = "Format" })

-- remove trailing whitespace when it's an open parenthesis
map("n", "J", remove_trailing_whitespace, { noremap = true, silent = true, desc = "Join line without whitespace if it's an open parenthesis" })

