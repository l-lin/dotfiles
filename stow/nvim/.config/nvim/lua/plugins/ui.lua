-- use custom keymaps
vim.g.tmux_navigator_no_mappings = 0

return {
  -- ###############
  -- disable plugins
  -- ###############
  -- remove colorschemes
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", enabled = false },
  { "catppuccin", enabled = false },

  {
    "rebelot/kanagawa.nvim",
    optional = true,
    opts = {
      keywordStyle = { bold = true, italic = false },
      colors = {
        palette = {
          lotusWhite0 = "#f2f2f2",
          lotusWhite1 = "#f2f2f2",
          lotusWhite2 = "#f2f2f2",
          lotusWhite3 = "#f2f2f2",
          lotusWhite4 = "#E6E6E6",
          lotusWhite5 = "#f2f2f2",
          lotusGreen = "#007872",
          lotusInk1 = "#363646",
          lotusInk2 = "#223249",
          lotusBlue4 = "#1561b8"
        },
        theme = {
          lotus = {
            ui = {
              bg_m3 = "#e6e6e6",
            },
          },
          all = {
            syn = {
              constant = "none",
              identifier = "none",
              number = "none",
              operator = "none",
              preproc = "none",
              punct = "none",
              special2 = "none",
              special3 = "none",
            },
          },
        },
      },
      overrides = function(colors)
        return {
          Constant = { bold = true },
          DiagnosticUnderlineError = { fg = colors.theme.diag.error },
          DiagnosticUnderlineWarn = { fg = colors.theme.diag.warning },
          DiagnosticUnderlineInfo = { fg = colors.theme.diag.info },
          DiagnosticUnderlineHint = { fg = colors.theme.diag.hint },
        }
      end,
    },
  },

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
        preset = {
          keys = {
            { icon = " ", key = "g", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "f", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
            { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
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
        { "<leader>fx", group = "execute" },
      },
      preset = "helix",
    },
  },



  -- #######################
  -- add new plugins
  -- #######################

  -- navigate between neovim and multiplexers
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    keys = {
      { "<M-C-h>", "<cmd>TmuxNavigateLeft<cr>", mode = { "n" }, silent = true, desc = "Navigate left" },
      { "<M-C-j>", "<cmd>TmuxNavigateDown<cr>", mode = { "n" }, silent = true, desc = "Navigate left" },
      { "<M-C-k>", "<cmd>TmuxNavigateUp<cr>", mode = { "n" }, silent = true, desc = "Navigate left" },
      { "<M-C-l>", "<cmd>TmuxNavigateRight<cr>", mode = { "n" }, silent = true, desc = "Navigate left" },
    },
  },

  -- color highlighter
  {
    "NvChad/nvim-colorizer.lua",
    lazy = false,
    opts = {},
  },
}
