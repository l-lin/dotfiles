require("true-zen").setup {
  modes = {
    ataraxis = {
      -- minimum size of main window
      minimum_writing_area = {
        width = 100,
        height = 54,
      }
    }
  }
}
local map = vim.api.nvim_set_keymap
map('n', '<leader>z', '<Cmd>TZAtaraxis<CR>', { noremap = true, desc = 'True Zen zoom window'})
