local function with_border(border_style)
  return {
    {
      "rebelot/kanagawa.nvim",
      optional = true;
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
    {
      "projekt0n/github-nvim-theme",
      optional = true;
      opts = {
        groups = {
          all = {
            NormalFloat = { bg = "none" },
            FloatBorder = { bg = "none" },
            LazyNormal = { bg = "none" },
            MasonNormal = { bg = "none" },
            HoverNormal = { bg = "none" },
            HoverBorder = { bg = "none" },
            SagaNormal = { bg = "none" },
            SagaBorder = { bg = "none" },
          },
        },
      },
    },
    {
      "nvim-cmp",
      opts = function(_, opts)
        local bordered = require("cmp.config.window").bordered
        local window_opts = {
          border = border_style,
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
    {
      "gitsigns.nvim",
      opts = {
        preview_config = {
          border = border_style,
        },
      },
    },
    {
      "nvim-lspconfig",
      opts = function(_, opts)
        -- Set LspInfo border
        require("lspconfig.ui.windows").default_options.border = border_style
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border_style })
        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = border_style })
        vim.diagnostic.config({ float = { border = border_style }})
        return opts
      end,
    },
    {
      "mason.nvim",
      opts = {
        ui = {
          border = border_style,
        },
      },
    },
    {
      "noice.nvim",
      opts = {
        presets = {
          lsp_doc_border = true,
        },
      },
    },
  }
end

return with_border("rounded")
