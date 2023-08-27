return {
  {
    "rebelot/kanagawa.nvim",
  },
  {
    "projekt0n/github-nvim-theme",
  },
  {
    "ellisonleao/gruvbox.nvim",
  },

  -- setup colorscheme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "github_light_high_contrast",
      defaults = {
        -- disable default keymaps as the window navigation overrides Navigator plugin's one
        keymaps = false,
      },
    },
  },
}
