return {
  -- #######################
  -- override default config
  -- #######################

  -- Use hlchunk instead to render the indent lines.
  {
    "folke/snacks.nvim",
    opts = {
      indent = { enabled = false },
    },
  },

  -- #######################
  -- add new plugins
  -- #######################

  -- Highlight indent line.
  {
    "shellRaining/hlchunk.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      chunk = {
        enable = true,
        chars = {
          horizontal_line = "─",
          vertical_line = "│",
          left_top = "╭",
          left_bottom = "╰",
          right_arrow = "─",
        },
        duration = 0,
        delay = 0,
        use_treesitter = true,
        textobject = "", -- No need to activate textobject, mini.ai is here for that!
        max_file_size = 1024 * 1024, -- Disable once the file is > 1MB!
        error_sign = true,
        style = {
          { fg = vim.g.colorscheme_faint },
          { fg = vim.g.colorscheme_error },
        },
      },
      blank = {
        enable = true,
      },
    },
  },
}
