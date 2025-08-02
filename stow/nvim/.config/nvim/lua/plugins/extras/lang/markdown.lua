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
        checked = { icon = "󰱒 ", highlight = "RenderMarkdownTodo", scope_highlight = "@markup.strikethrough" },
        unchecked = { icon = "󰄱 ", highlight = "RenderMarkdownUnchecked", scope_highlight = nil },
        custom = {
          skipped = { raw = "[-]", rendered = "✘ ", highlight = "RenderMarkdownError", scope_highlight = "@markup.strikethrough" },
          postponed = { raw = "[>]", rendered = "󰥔 ", highlight = "RenderMarkdownChecked", scope_highlight = nil },
        },
      },
      heading = {
        enabled = true,
        icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
      },
      code = { border = "thin" },
    },
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

  -- add keymaps to which-key
  {
    "folke/which-key.nvim",
    ft = "markdown",
    opts = {
      spec = {
        {
          "<M-l>",
          require("plugins.custom.lang.markdown").convert_or_toggle_task,
          desc = "Convert bullet to a task or insert new task bullet or toggle task",
          mode = { "n", "i" },
          noremap = true,
        },
      },
    },
  },

  -- Disable LSP as it's always crashing in my notes project.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {
          enabled = false,
        },
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

  -- add wiki-links
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "l-lin/blink-cmp-wiki-links" },
    opts = {
      sources = {
        default = { "wiki_links" },
        providers = {
          wiki_links = {
            name = "wiki_links",
            module = "blink-cmp-wiki-links",
            score_offset = 85,
          },
        },
      },
    },
  },
}
