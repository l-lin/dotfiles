return {
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    opts = {
      set_dark_mode = function()
        -- For some reason, I need to call it twice to have all the right
        -- colors, like in markdown or the TODO comments.
        vim.cmd("colorscheme kanagawa")
        vim.cmd("colorscheme kanagawa")
      end,
      set_light_mode = function()
        vim.cmd("colorscheme github_light_high_contrast")
      end,
      update_interval = 3000,
      fallback = "dark",
    },
  },
}
