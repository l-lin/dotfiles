return {
  -- markdown table
  {
    "dhruvasagar/vim-table-mode",
    ft = "md",
  },
  -- fuzzy finding anything anywhere
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<C-b>",
        "<cmd>Telescope lsp_definitions<cr>",
        silent = true,
        desc = "Goto definition (Ctrl+b)",
      },
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
      -- add pictograms to cmp
      "onsails/lspkind.nvim",
      -- lsp based
      "hrsh7th/cmp-nvim-lsp",
      -- buffer based
      "hrsh7th/cmp-buffer",
      -- filepath based
      "hrsh7th/cmp-path",
      -- command based
      -- "hrsh7th/cmp-cmdline",
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
    },
    opts = function(_, opts)
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      opts.mapping = cmp.mapping.preset.insert({
        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-Space>"] = cmp.mapping.complete(),
        -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ["<C-e>"] = cmp.mapping.confirm({ select = true }),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
        -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ["<S-CR>"] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif cmp.visible() then
            cmp.select_next_item()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      })
      opts.sources = cmp.config.sources(vim.list_extend(opts.sources, {
        { name = "nvim_lsp_signature_help", priority = 7 },
        { name = "nvim_lsp",                priority = 6 },
        { name = "nvim_lua",                priority = 5 },
        { name = "luasnip",                 priority = 4 },
        { name = "path",                    priority = 3 },
        { name = "emoji",                   priority = 2, option = { insert = true } },
        { name = "tmux",                    priority = 1 },
      }))
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
  },
}
