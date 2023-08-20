-- Set border of some LazyVim plugins to rounded
local border_style = "rounded"

return {
  -- lazyvim.plugins.coding
  {
    "nvim-cmp",
    opts = function(_, opts)
      local bordered = require("cmp.config.window").bordered
      return vim.tbl_deep_extend("force", opts, {
        window = {
          completion = bordered(border_style),
          documentation = bordered(border_style),
        },
      })
    end,
  },
  -- lazyvim.plugins.editor
  {
    "which-key.nvim",
    opts = {
      window = {
        border = border_style,
      },
    },
  },
  {
    "gitsigns.nvim",
    opts = {
      preview_config = {
        border = border_style,
      },
    },
  },
  -- lazyvim.plugins.lsp
  {
    "nvim-lspconfig",
    opts = function(_, opts)
      -- Set LspInfo border
      require("lspconfig.ui.windows").default_options.border = border_style
      return opts
    end,
  },
  {
    "glepnir/lspsaga.nvim",
    opts = {
      ui = {
        border = border_style,
      },
    },
  },
  {
    "null-ls.nvim",
    opts = {
      border = border_style,
    },
  },
  {
    "mason.nvim",
    opts = {
      ui = {
        border = border_style,
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
