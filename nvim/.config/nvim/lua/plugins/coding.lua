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

-- deprioritize kinds, e.g. snippets at the bottom
-- from: https://www.reddit.com/r/neovim/comments/14k7pbc/what_is_the_nvimcmp_comparatorsorting_you_are/
local function deprio(kind)
  return function(e1, e2)
    if e1:get_kind() == kind then
      return false
    end
    if e2:get_kind() == kind then
      return true
    end
  end
end

local java_unwanted_method_names = { "wait", "hashCode", "notify", "notifyAll" }
local function has_value (tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end
local function move_java_unwanted_methods_to_bottom(e1, e2)
  if has_value(java_unwanted_method_names, e1.completion_item.label) then
    return false
  end
  if has_value(java_unwanted_method_names, e2.completion_item.label) then
    return true
  end
  return nil
end

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
    },
    opts = function(_, opts)
      local cmp = require("cmp")
      local compare = require("cmp.config.compare")
      local types = require("cmp.types")
      local luasnip = require("luasnip")
      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      -- more LOC in one file so that cmp will consider local
      compare.locality.lines_count = 300

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
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "buffer" },
        { name = "tmux" },
      }, {
        { name = "path" },
        { name = "emoji", option = { insert = true } },
      })
      opts.sorting = {
        priority_weight = 2,
        comparators = {
          -- put snippets at the bottom, for better method exploration
          deprio(types.lsp.CompletionItemKind.Snippet),
          deprio(types.lsp.CompletionItemKind.Text),
          deprio(types.lsp.CompletionItemKind.Keyword),
          move_java_unwanted_methods_to_bottom,
          compare.offset,
          compare.exact,
          compare.locality,
          compare.recently_used,
          compare.score,
          compare.order,
        },
      }
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
