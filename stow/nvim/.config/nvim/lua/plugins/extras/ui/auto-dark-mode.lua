return {
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    opts = {
      -- For some reason, I need to call it twice to have all the right
      -- colors, like in markdown or the TODO comments.
      set_dark_mode = function()
        vim.cmd("colorscheme " .. vim.g.dark_colorscheme)
        vim.cmd("colorscheme " .. vim.g.dark_colorscheme)
      end,
      set_light_mode = function()
        vim.cmd("colorscheme " .. vim.g.light_colorscheme)
        vim.cmd("colorscheme " .. vim.g.light_colorscheme)
      end,
      update_interval = 3000,
      fallback = "dark",
    },
  },
}
