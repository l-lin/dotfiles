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
      "saghen/blink.cmp",
      optional = true;
      opts = {
        completion = {
          menu = {
            border = border_style,
            winhighlight = 'Normal:None,FloatBorder:None,CursorLine:BlinkCmpMenuSelection,Search:None',
            scrollbar = false,
          },
          documentation = {
            window = {
              border = border_style,
              scrollbar = false,
            },
          },
        },
      },
    },
    {
      "lewis6991/gitsigns.nvim",
      optional = true;
      opts = {
        preview_config = {
          border = border_style,
        },
      },
    },
    {
      "neovim/nvim-lspconfig",
      optional = true;
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
      "mason-org/mason.nvim",
      optional = true;
      opts = {
        ui = {
          border = border_style,
        },
      },
    },
    {
      "folke/noice.nvim",
      optional = true;
      opts = {
        presets = {
          lsp_doc_border = true,
        },
      },
    },
  }
end

return with_border("rounded")
