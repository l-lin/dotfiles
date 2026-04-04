--
-- Seamless navigation between tmux panes and vim splits
--

-- use custom keymaps
-- src: https://github.com/christoomey/vim-tmux-navigator#custom-key-bindings
vim.g.tmux_navigator_no_mappings = 1

local map = vim.keymap.set
map("n", "<M-C-h>", "<cmd>TmuxNavigateLeft<cr>", { desc = "Navigate left", silent = true })
map("n", "<M-C-j>", "<cmd>TmuxNavigateDown<cr>", { desc = "Navigate down", silent = true })
map("n", "<M-C-k>", "<cmd>TmuxNavigateUp<cr>", { desc = "Navigate up", silent = true })
map("n", "<M-C-l>", "<cmd>TmuxNavigateRight<cr>", { desc = "Navigate right", silent = true })
