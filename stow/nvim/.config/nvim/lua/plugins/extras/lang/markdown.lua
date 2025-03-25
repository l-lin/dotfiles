return {
  -- I do not use the preview feature.
  { "iamcco/markdown-preview.nvim", enabled = false },

  -- #######################
  -- override default config
  -- #######################

  -- Plugin to improve viewing Markdown files in Neovim.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      checkbox = {
        enabled = true,
        right_pad = 0,
      },
      heading = {
        enabled = true,
        icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
      },
    }
  },

  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        -- Disable linter, let me freely write anything without hassle!
        -- src: https://github.com/LazyVim/LazyVim/issues/2437
        markdown = {},
      },
    },
  },

  -- #######################
  -- add new plugins
  -- #######################

  -- markdown table
  {
    "dhruvasagar/vim-table-mode",
    ft = "markdown",
    keys = {
      { "<leader>tm", false },
      {
        "<leader>cM",
        "<cmd>TableModeToggle<cr>",
        noremap = true,
        silent = true,
        desc = "Toggle Markdown table",
      },
    },
  },
}
