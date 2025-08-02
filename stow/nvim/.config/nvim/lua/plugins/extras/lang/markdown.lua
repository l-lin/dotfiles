return {
  -- Plugin to improve viewing Markdown files in Neovim.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "norg", "rmd", "org", "codecompanion" },
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
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
        border = "thin"
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      Snacks.toggle({
        name = "Render Markdown",
        get = function()
          return require("render-markdown.state").enabled
        end,
        set = function(enabled)
          local m = require("render-markdown")
          if enabled then
            m.enable()
          else
            m.disable()
          end
        end,
      }):map("<leader>um")
    end,
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
