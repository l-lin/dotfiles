local M = {}

M.change_highlight = function()
  local bg = require("plugins.gruvbox").get_background_color()
  vim.api.nvim_set_hl(0, "WhichKeyFloat", { bg = bg })
  vim.api.nvim_set_hl(0, "WhichKeyBorder", { bg = bg })
end

M.setup = function()
  local config = {
    disable = {
      filetypes = { "TelescopePrompt", "dashboard" }
    },
    window = {
      border = "rounded",
    }
  }
  local registry = {
    ["<leader>"] = {
      c = { name = "+Code" },
      d = { name = "+Dap" },
      f = {
        name = "Find",
        g = { name = "Git" },
        t = { name = "Text" },
      },
      g = { name = "Git" },
      l = { name = "Language" },
      n = { name = "Navigation" },
      r = { name = "Search and replace" },
      s = { name = "Session persistence" },
      t = { name = "Markdown table mode" },
      v = { name = "Nvim" },
      w = { name = "Whitespace" },
      x = { name = "Trouble" },
    }
  }

  local wk = require("which-key")
  wk.register(registry)
  wk.setup(config)

  M.change_highlight()
end

return M
