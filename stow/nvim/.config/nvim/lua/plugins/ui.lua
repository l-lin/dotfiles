return {
  -- #######################
  -- override default config
  -- #######################

  -- nice UI for messages, cmdline and popupmenu
  {
    "folke/noice.nvim",
    opts = {
      lsp = {
        progress = {
          view = "virtualtext",
        },
      },
    },
    keys = {
      { "<c-f>", false },
      { "<c-b>", false },
      { "<c-d>", function() if not require("noice.lsp").scroll(4) then return "<c-d>" end end, silent = true, expr = true, desc = "Scroll forward", mode = {"i", "n", "s"} },
      { "<c-u>", function() if not require("noice.lsp").scroll(-4) then return "<c-u>" end end, silent = true, expr = true, desc = "Scroll backward", mode = {"i", "n", "s"}},
    }
  },

  -- dashboard
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        sections = {
          { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
          { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
          { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
          { section = "startup" },
        },
      },
    },
  },

  -- buffer line (top bar)
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        show_close_icon = false,
        show_buffer_close_icons = false,
      },
    },
    keys = {
      { "<S-h>", false },
      { "<S-l>", false },
    },
  },

  -- status line (bottom bar)
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        section_separators = "",
        component_separators = "",
      },
    },
  },

  -- show available keymaps + description as you type them
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>y", group = "yank" },
      },
      preset = "modern",
    },
  },



  -- #######################
  -- add new plugins
  -- #######################

  -- navigate between neovim and multiplexers
  {
    "numToStr/Navigator.nvim",
    keys = {
      { "<C-h>", "<cmd>NavigatorLeft<cr>",  mode = { "n", "t" }, silent = true, desc = "Navigate left" },
      { "<C-l>", "<cmd>NavigatorRight<cr>", mode = { "n", "t" }, silent = true, desc = "Navigate right" },
      { "<C-k>", "<cmd>NavigatorUp<cr>",    mode = { "n", "t" }, silent = true, desc = "Navigate up" },
      { "<C-j>", "<cmd>NavigatorDown<cr>",  mode = { "n", "t" }, silent = true, desc = "Navigate down" },
    },
    cmd = {
      "NavigatorUp",
      "NavigatorDown",
      "NavigatorRight",
      "NavigatorLeft",
    },
    config = function()
      require("Navigator").setup({})
    end,
  },

  -- color highlighter
  {
    "NvChad/nvim-colorizer.lua",
    lazy = false,
    opts = {
      user_default_options = {
        mode = "virtualtext",
      },
    },
  },
}
