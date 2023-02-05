-- tutorials:
-- https://github.com/nanotee/nvim-lua-guide
-- https://vonheikemen.github.io/devlog/tools/configuring-neovim-using-lua/
--
-- inspirations:
-- https://github.com/voltux/dotfiles
--https://github.com/voltux/dotfiles
require('settings')
require('appearance')
require('keymaps')
pcall(require, 'impatient')
require('plugins')
