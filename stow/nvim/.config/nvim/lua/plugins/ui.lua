return {
  -- ###############
  -- disable plugins
  -- ###############
  -- remove colorschemes
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", enabled = false },
  { "catppuccin", enabled = false },

  -- Disable bufferline (topbar), let's use Telescope/fzf for everything!
  {
    "akinsho/bufferline.nvim",
    enabled = false,
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
      lazygit = {
        win = {
          width = 0,
          height = 0
        }
      },
      notifier = {
        enabled = true,
        -- Place notifications from top to bottom.
        top_down = false,
      }
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
        -- No need to display the mode.
        lualine_a = {},
        lualine_c = {
          -- No need to display the root dir.
          {
            "diagnostics",
            symbols = {
              error = LazyVim.config.icons.diagnostics.Error,
              warn = LazyVim.config.icons.diagnostics.Warn,
              info = LazyVim.config.icons.diagnostics.Info,
              hint = LazyVim.config.icons.diagnostics.Hint,
            },
          },
          { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
          -- No need to display the treesitter location.
          { LazyVim.lualine.pretty_path({ modified_hl = '' }) },
        },
        -- No need to display the clock.
        lualine_z = {},
      }
    },
  },

  -- show available keymaps + description as you type them
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>y", group = "yank" },
      },
      preset = "helix",
    },
  },



  -- #######################
  -- add new plugins
  -- #######################

  -- navigate between neovim and multiplexers
  {
    "numToStr/Navigator.nvim",
    keys = {
      { "<C-h>", "<cmd>NavigatorLeft<cr>", mode = { "n", "t" }, silent = true, desc = "Navigate left" },
      { "<C-l>", "<cmd>NavigatorRight<cr>", mode = { "n", "t" }, silent = true, desc = "Navigate right" },
      { "<C-k>", "<cmd>NavigatorUp<cr>", mode = { "n", "t" }, silent = true, desc = "Navigate up" },
      { "<C-j>", "<cmd>NavigatorDown<cr>", mode = { "n", "t" }, silent = true, desc = "Navigate down" },
    },
    cmd = {
      "NavigatorUp",
      "NavigatorDown",
      "NavigatorRight",
      "NavigatorLeft",
    },
    opts = {},
  },

  -- color highlighter
  {
    "NvChad/nvim-colorizer.lua",
    lazy = false,
    opts = {},
  },
}
