require("nvim-tree").setup {
  view = {
    adaptive_size = true,
  }
}
require('nvim-tree.view').View.winopts.signcolumn = 'no'

vim.api.nvim_set_keymap('n', '<A-1>', ':NvimTreeToggle<CR>', { noremap = true, desc = 'NvimTree Toggle' })
