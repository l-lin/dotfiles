local default_sources = { "lsp", "snippets", "path", "buffer", "copilot" }
local per_filetype = {
  markdown = { "wiki_links", inherit_defaults = true },
  lua = { "lazydev", inherit_defaults = true },
}
local providers = {
  copilot = {
    async = true,
    module = "blink-copilot",
    name = "copilot",
    score_offset = 100,
  },
  lazydev = {
    module = "lazydev.integrations.blink",
    name = "lazydev",
    score_offset = 99,
  },
  wiki_links = {
    module = "blink-cmp-wiki-links",
    name = "wiki_links",
    score_offset = 85,
  },
}

local function setup()
  require("blink.cmp").setup({
    fuzzy = {
      implementation = "prefer_rust",
    },
    appearance = {
      nerd_font_variant = "mono",
    },
    cmdline = {
      enabled = true,
      keymap = {
        preset = "cmdline",
        ["<Right>"] = false,
        ["<Left>"] = false,
      },
      completion = {
        list = { selection = { preselect = false } },
        menu = {
          auto_show = function()
            return vim.fn.getcmdtype() == ":"
          end,
        },
        ghost_text = { enabled = true },
      },
    },
    completion = {
      accept = {
        auto_brackets = { enabled = true },
      },
      menu = {
        border = "rounded",
        scrollbar = false,
        winhighlight = "Normal:None,FloatBorder:None,CursorLine:BlinkCmpMenuSelection,Search:None",
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
        window = {
          border = "rounded",
          scrollbar = false,
        },
      },
      ghost_text = { enabled = true },
    },
    keymap = {
      preset = "enter",
      ["<C-e>"] = { "select_and_accept" },
    },
    snippets = {
      preset = "default",
    },
    sources = {
      default = default_sources,
      per_filetype = per_filetype,
      providers = providers,
    },
  })
end

---@type vim.pack.Spec[]
return {
  -- Set of preconfigured snippets for different languages.
  {
    src = "https://github.com/rafamadriz/friendly-snippets",
  },
  -- provides fuzzy matching for markdown file names and automatically formats them as wiki links
  {
    src = "https://codeberg.org/l-lin/blink-cmp-wiki-links",
  },
  -- ⚙️ Configurable GitHub Copilot blink.cmp source for Neovim
  {
    src = "https://github.com/fang2hou/blink-copilot",
  },
  -- Performant, batteries-included completion plugin for Neovim
  {
    src = "https://github.com/saghen/blink.cmp",
    version = vim.version.range("1.x"),
    data = {
      setup = function()
        vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter" }, {
          once = true,
          callback = setup,
        })
      end,
    },
  },
}
