--
-- Performant, batteries-included completion plugin for Neovim.
--

--
-- Setup
--
require("blink.cmp").setup({
  fuzzy = {
    implementation = 'prefer_rust',
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
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
    },
    ghost_text = { enabled = false },
  },
  keymap = {
    preset = "enter",
    ["<C-e>"] = { "select_and_accept" },
  },
  snippets = {
    preset = "default",
  },
  sources = {
    default = { 'lsp', 'snippets', 'path', 'buffer' },
    per_filetype = {},
    providers = {},
  },
})
