require('flash').setup({
  search = {
    mode = 'search',
  },
  label = {
    rainbow = {
      enabled = true,
    }
  }
})
local map = vim.keymap.set

map({ 'n', 'x', 'o' }, 's', require('flash').jump, { noremap = true, silent = true, desc = 'Flash' })
map({ 'n', 'x', 'o' }, '<leader>nf', require('flash').jump, { noremap = true, silent = true, desc = 'Flash (or use s)' })
map({ 'n', 'o', 'x' }, 'S', require('flash').treesitter, { noremap = true, silent = true, desc = 'Flash treesitter' })
map({ 'n', 'o', 'x' }, '<leader>nt', require('flash').treesitter, { noremap = true, silent = true, desc = 'Flash treesitter (or use S)' })