-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- disable CMP completion menu transparency
vim.opt.pumblend = 0

-- set 7 lines to the cursor when moving vertically
--vim.opt.scrolloff = 7

-- enable word wrap
-- vim.opt.wrap = true

-- set background
-- commented because it's now set by home-manager
--vim.o.bg = "dark"

-- disable auto-formatting
vim.g.autoformat = false

-- set to 2 spaces
vim.o.tabstop = 2
vim.o.shiftwidth = vim.o.tabstop

-- do not have long lines
vim.o.textwidth = 80

-- lazyvim config
-- use telescope
vim.g.lazyvim_picker = "telescope"
-- disable animations, let's go fast!
vim.g.snacks_animate = false
