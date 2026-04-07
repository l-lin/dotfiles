-- set background
vim.o.bg = "light"
-- Global variables ftw! Too lazy to have something "smart" but complex...
vim.g.colorscheme_faint = "#5e5e5e"
vim.g.colorscheme_error = "#c4331d"
vim.g.colorscheme = "grey"

return {
  { 'l-lin/nvim-grey' },
  -- setup colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "grey",
    },
  },
}

