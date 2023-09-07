return {
  {
    "rebelot/kanagawa.nvim",
  },
  {
    "projekt0n/github-nvim-theme",
    opts = {
      specs = {
        github_light_high_contrast = {
          bg0 = "#f2eede",
          bg1 = "#f2eede",
          canvas = {
            default = "#ffffff",
            inset = "#ffffff",
            overlay = "#ffffff",
          },
        },
      },
    },
    config = function(_, opts)
      require("github-theme").setup(opts)
    end,
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
