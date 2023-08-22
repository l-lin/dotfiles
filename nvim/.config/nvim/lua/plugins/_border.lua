if vim.g.border_style == "none" then
  return {
    {
      "rebelot/kanagawa.nvim",
      opts = {
        overrides = function(colors)
          local theme = colors.theme
          return {
            LazyNormal = { bg = theme.ui.bg_m1 },
            MasonNormal = { bg = theme.ui.bg_m1 },
            TelescopeTitle = { fg = theme.ui.special, bold = true },
            TelescopePromptNormal = { bg = theme.ui.bg_p1 },
            TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
            TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
            TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
            TelescopePreviewNormal = { bg = theme.ui.bg_dim },
            TelescopePreviewBorder = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },
          }
        end,
      },
    },
  }
end

return {
  {
    "rebelot/kanagawa.nvim",
    opts = {
      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none",
              float = {
                bg = "none",
              },
            },
          },
        },
      },
      overrides = function()
        return {
          NormalFloat = { bg = "none" },
          FloatBorder = { bg = "none" },
          LazyNormal = { bg = "none" },
          MasonNormal = { bg = "none" },
          HoverNormal = { bg = "none" },
          HoverBorder = { bg = "none" },
          SagaNormal = { bg = "none" },
          SagaBorder = { bg = "none" },
        }
      end,
    },
  },
  -- lazyvim.plugins.coding
  {
    "nvim-cmp",
    opts = function(_, opts)
      local bordered = require("cmp.config.window").bordered
      local window_opts = {
        border = vim.g.border_style,
        scrollbar = false,
        col_offset = -4,
        side_padding = 0,
      }
      return vim.tbl_deep_extend("force", opts, {
        window = {
          completion = bordered(window_opts),
          documentation = bordered(window_opts),
        },
      })
    end,
  },
  -- lazyvim.plugins.editor
  {
    "which-key.nvim",
    opts = {
      window = {
        border = vim.g.border_style,
      },
    },
  },
  {
    "gitsigns.nvim",
    opts = {
      preview_config = {
        border = vim.g.border_style,
      },
    },
  },
  -- lazyvim.plugins.lsp
  {
    "nvim-lspconfig",
    opts = function(_, opts)
      -- Set LspInfo border
      require("lspconfig.ui.windows").default_options.border = vim.g.border_style
      return opts
    end,
  },
  {
    "glepnir/lspsaga.nvim",
    opts = {
      ui = {
        border = vim.g.border_style,
      },
    },
  },
  {
    "null-ls.nvim",
    opts = {
      border = vim.g.border_style,
    },
  },
  {
    "mason.nvim",
    opts = {
      ui = {
        border = vim.g.border_style,
      },
    },
  },
  -- lazyvim.plugins.ui
  {
    "noice.nvim",
    opts = {
      presets = {
        lsp_doc_border = true,
      },
    },
  },
}
