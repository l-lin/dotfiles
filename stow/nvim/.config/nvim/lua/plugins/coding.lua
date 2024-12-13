return {
  -- #######################
  -- override default config
  -- #######################

  -- fuzzy finding anything anywhere
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<M-6>",
        "<cmd>Telescope diagnostics<cr>",
        noremap = true,
        silent = true,
        desc = "Diagnostic (Alt+6)",
      },
    },
  },

  -- autocompletion engine
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "enter",
        ['<C-e>'] = { 'select_and_accept' },
      },
    },
  },

  -- autopairs - not quite as good as nvim-autopairs
  {
    "echasnovski/mini.pairs",
    enabled = false,
  },

  -- #######################
  -- add new plugins
  -- #######################

  -- markdown table
  {
    "dhruvasagar/vim-table-mode",
    ft = "markdown",
    keys = {
      {
        "<leader>tm",
        false,
      },
      {
        "<leader>cM",
        "<cmd>TableModeToggle<cr>",
        noremap = true,
        silent = true,
        desc = "Toggle Markdown table",
      },
    },
  },

  -- snippet engine
  -- NOTE: Not taking the one from LazyVim because it's adding some nvim-cmp config with tab, which I don't want.
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip.loaders.from_snipmate").lazy_load()
        require("luasnip.loaders.from_lua").lazy_load()
      end,
    },
    keys = function()
      return {}
    end,
  },

  -- autopairs - better than mini.pairs in my taste
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
}
