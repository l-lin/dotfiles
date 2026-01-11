-- Keymaps are automatically loaded on the VeryLazy event.
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua.
-- Add any additional keymaps here.

-- remove keymaps set globally by LazyVim
-- use default H and L to navigate
vim.keymap.del("n", "<S-h>")
vim.keymap.del("n", "<S-l>")
-- remove those keymaps so that I use the <M-C-hjkl> instead
vim.keymap.del("n", "<C-h>")
vim.keymap.del("n", "<C-j>")
vim.keymap.del("n", "<C-k>")
vim.keymap.del("n", "<C-l>")

-- Remove floating terminal keyamps (I use Tmux, no need for embedded terminal).
vim.keymap.del("n", "<leader>fT")
vim.keymap.del("n", "<leader>ft")
vim.keymap.del("n", "<c-/>")
vim.keymap.del("n", "<c-_>")


local map = vim.keymap.set

-- buffer
-- Same behavior as browsers (muscle memory).
map("n", "<F28>", "<cmd>bd<CR>", { noremap = true, silent = true, desc = "Close current buffer (Ctrl+F4)" })

-- yank file path / name
map("n", "<leader>yf", "<cmd>let @+=expand('%:.')<CR>", { noremap = true, desc = "Copy current buffer relative path to clipboard" })
map("n", "<leader>yF", "<cmd>let @+=expand('%:p')<CR>", { noremap = true, desc = "Copy current buffer absolute path to clipboard" })
map("n", "<leader>yn", "<cmd>let @+=expand('%:t')<CR>", { noremap = true, desc = "Copy current buffer file name to clipboard" })

-- LSP
map("n", "<leader>ci", vim.lsp.buf.implementation, { desc = "Goto implementation" })
map("n", "<leader>ct", vim.lsp.buf.type_definition, { desc = "Goto Type definition" })
map("n", "<leader>cu", vim.lsp.buf.references, { desc = "References / Usages" })

-- navigation
-- Always put cursor at middle of screen.
map("n", "<C-d>", "<C-d>zz", { noremap = true })
map("n", "<C-u>", "<C-u>zz", { noremap = true })
map("n", "<S-h>", "<S-h>zz", { noremap = true })
map("n", "<S-l>", "<S-l>zz", { noremap = true })
map("n", "{", "{zz", { noremap = true })
map("n", "}", "}zz", { noremap = true })
map("n", "j", function() require("helpers.cursor").move_to_middle_of_screen("j") end, { noremap = true })
map("n", "k", function() require("helpers.cursor").move_to_middle_of_screen("k") end, { noremap = true })
-- search
map("n", "n", "nzzzv", { noremap = true })
map("n", "N", "Nzzzv", { noremap = true })

-- tab
map("n", "]<tab>", "<cmd>tabnext<cr>", { noremap = true, desc = "Next Tab" })
map("n", "[<tab>", "<cmd>tabprevious<cr>", { noremap = true, desc = "Previous Tab" })

-- special keymap to cut to black hole, so I don't lose what I yank to my register '+'
map({ "n", "v" }, "<M-d>", '"_d', { noremap = true })

-- diagnostics (same behavior as IntelliJ)
map("n", "<F25>", vim.diagnostic.open_float, { desc = "Line Diagnostics (Ctrl+F1)" })
map("n", "<F2>", function () vim.diagnostic.jump({ count = 1 }) end, { desc = "Next diagnostic (F2)" })

-- do not include white space characters when using $ in visual mode, see https://vi.stackexchange.com/q/12607/15292
map("x", "$", "g_")

-- remove trailing whitespaces
map("n", "gJ", function() vim.api.nvim_command("norm! JdiW") end, { noremap = true, silent = true, desc = "Join line without whitespace" })

-- Toggle executable permission on current file.
map("n", "<leader>fxt", require("helpers.file").toggle_executable_permission, { desc = "Toggle executable permission" })

-- If this is a bash script, make it executable, and execute it in a tmux pane on the right
map("n", "<leader>fxx", require("helpers.file").execute_bash_script, { desc = "Execute bash script" })

-- Do not select the next search element, so that I can easily do `cgn`.
map("n", "*", "*N", { noremap = true, silent = true })
map("n", "#", "#N", { noremap = true, silent = true })

-- Open link under cursor with either browser in private window for youtube links, short reponame in browser, or fallback to gx
map("n", "gx", require("helpers.open").smart_open, { desc = "Smart open URL or filepath" })

-- Scratch buffer mode: quickly exit neovim with classic keybinds.
if vim.env.NVIM_SCRATCH then
  map("i", "<C-s>", "<Esc>ZQ", { desc = "Quit scratch buffer" })
  map("n", "q", "ZQ", { desc = "Quit scratch buffer" })
end
