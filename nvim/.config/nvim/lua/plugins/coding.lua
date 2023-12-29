return {
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
    "hrsh7th/nvim-cmp",
    dependencies = {
      -- lsp based
      "hrsh7th/cmp-nvim-lsp",
      -- buffer based
      "hrsh7th/cmp-buffer",
      -- filepath based
      "hrsh7th/cmp-path",
      -- command based
      "hrsh7th/cmp-cmdline",
      -- autocompletion on lsp function/class signature
      "hrsh7th/cmp-nvim-lsp-signature-help",
      -- lua support
      "hrsh7th/cmp-nvim-lua",
      "saadparwaiz1/cmp_luasnip",
      -- emoji support
      "hrsh7th/cmp-emoji",
      -- omni
      "hrsh7th/cmp-omni",
      -- autocompletion from tmux panes
      "andersevenrud/cmp-tmux",
      -- buffer lines based
      "amarakon/nvim-cmp-buffer-lines",
      -- textDocument / documentSymbol search
      "hrsh7th/cmp-nvim-lsp-document-symbol",
      -- sql autocompletion
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "psql" } },
    },
    opts = function(_, opts)
      local cmp = require("cmp")
      local compare = require("cmp.config.compare")
      local luasnip = require("luasnip")
      local custom_comparators = require("plugins.custom.cmp.comparators")
      local custom_formatters = require("plugins.custom.cmp.formatters")

      opts.mapping = cmp.mapping.preset.insert({
        ["<C-u>"] = cmp.mapping.scroll_docs(-4),
        ["<C-d>"] = cmp.mapping.scroll_docs(4),
        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-Space>"] = cmp.mapping.complete(),
        -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ["<C-e>"] = cmp.mapping.confirm({ select = true }),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ["<S-CR>"] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
        -- navigate through snippet jumpables
        ["<C-l>"] = cmp.mapping(function(fallback)
          if luasnip.in_snippet() and luasnip.jumpable() then
            luasnip.jump(1)
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<C-h>"] = cmp.mapping(function(fallback)
          if luasnip.in_snippet() and luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      })
      opts.sources = cmp.config.sources({
        { name = "codeium" },
        { name = "nvim_lsp" },
        { name = "luasnip" },
      }, {
        { name = "path" },
        { name = "buffer" },
        { name = "tmux" },
        { name = "emoji", option = { insert = true } },
      })
      opts.sorting = {
        priority_weight = 2,
        comparators = {
          -- Java methods that we never use should be at the bottom.
          custom_comparators.deprioritize_labels({ "wait", "hashCode", "notify", "notifyAll", "clone", "finalize" }),
          -- custom_comparators.deprioritize_kind(types.lsp.CompletionItemKind.Text),
          compare.offset,
          compare.exact,
          compare.score,
          compare.recently_used,
          custom_comparators.kind,
          compare.locality,
          compare.order,
        },
      }
      opts.formatting = {
        fields = { "kind", "abbr", "menu" },
        format = custom_formatters.kind_to_the_left,
      }
      -- do not select first item until I say so!
      opts.preselect = cmp.PreselectMode.None
      opts.completion = {
        completeopt = "menu,menuone,noselect",
      }
    end,
    config = function(_, opts)
      local cmp = require("cmp")
      cmp.setup(opts)

      cmp.setup.filetype("gitcommit", {
        sources = cmp.config.sources({
          { name = "buffer" },
          { name = "tmux" },
          { name = "emoji", option = { insert = true } },
        }),
      })
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "nvim_lsp_document_symbol" },
          { name = "buffer" },
        },
      })
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
      cmp.setup.filetype({ "sql", "psql" }, {
        sources = cmp.config.sources({
          { name = "vim-dadbod-completion" },
        }),
      })
    end,
  },

  -- snippet engine
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
    -- enable supertab, see https://www.lazyvim.org/configuration/recipes#supertab
    keys = function()
      return {}
    end,
  },
}
