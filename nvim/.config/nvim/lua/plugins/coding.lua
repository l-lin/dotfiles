-- shamelessly copied and adapted from https://github.com/onsails/lspkind.nvim
local function cmp_format(opts, _, vim_item)
  local icons = require("lazyvim.config").icons.kinds
  if icons[vim_item.kind] then
    vim_item.kind = icons[vim_item.kind] .. vim_item.kind
  end

  if opts.maxwidth ~= nil then
    if opts.ellipsis_char == nil then
      vim_item.abbr = string.sub(vim_item.abbr, 1, opts.maxwidth)
    else
      local label = vim_item.abbr
      local truncated_label = vim.fn.strcharpart(label, 0, opts.maxwidth)
      if truncated_label ~= label then
        vim_item.abbr = truncated_label .. opts.ellipsis_char
      end
    end
  end
  return vim_item
end

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
        remap = true,
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
      local compare = require("cmp.config.compare")
      local luasnip = require("luasnip")
      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      -- more LOC in one file so that cmp will consider local
      compare.locality.lines_count = 300

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
        { name = "emoji", option = { insert = true } },
        { name = "tmux" },
      }))
      opts.formatting = {
        fields = { "kind", "abbr", "menu" },
        format = function(entry, vim_item)
          local item = cmp_format({ maxwidth = 50, ellipsis_char = "..." }, entry, vim_item)
          local strings = vim.split(item.kind, "%s", { trimempty = true })
          item.kind = " " .. (strings[1] or "") .. " "
          item.menu = "    " .. (strings[2] or "")
          return item
        end,
      }
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
