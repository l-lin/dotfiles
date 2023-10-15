return {
  -- nice UI for messages, cmdline and popupmenu
  {
    "folke/noice.nvim",
    opts = {
      popupmenu = {
        backend = "cmp",
      },
    },
    keys = {
      { "<c-f>", false },
      { "<c-b>", false },
      { "<c-d>", function() if not require("noice.lsp").scroll(4) then return "<c-d>" end end, silent = true, expr = true, desc = "Scroll forward", mode = {"i", "n", "s"} },
      { "<c-u>", function() if not require("noice.lsp").scroll(-4) then return "<c-u>" end end, silent = true, expr = true, desc = "Scroll backward", mode = {"i", "n", "s"}},
    }
  },

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

  -- dashboard
  {
    "nvimdev/dashboard-nvim",
    opts = {
      config = {
        header = {
          val = "",
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
  },

  -- status line (bottom bar)
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        section_separators = "",
        component_separators = "",
      },
      sections = {
        lualine_c = {
          {
            "diagnostics",
            symbols = {
              error = require("lazyvim.config").icons.diagnostics.Error,
              warn = require("lazyvim.config").icons.diagnostics.Warn,
              info = require("lazyvim.config").icons.diagnostics.Info,
              hint = require("lazyvim.config").icons.diagnostics.Hint,
            },
          },
          { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
          -- NOTE: filename for java third party dependencies with jdtls have path like jdt://contents/..., so generating lots of errors => disable it
          -- { "filename", path = 1, symbols = { modified = "  ", readonly = "", unnamed = "" } },
        },
      },
    },
  },

  -- show available keymaps + description as you type them
  {
    "folke/which-key.nvim",
    opts = {
      defaults = {
        ["<leader>v"] = { name = "+nvim" },
      },
    },
  },
}
