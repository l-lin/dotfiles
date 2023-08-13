local wk = require("which-key")
wk.register({
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
    t = { name = "Markdown table mode" },
    v = { name = "Nvim" },
    w = { name = "Whitespace" },
    x = { name = "Trouble" },
  }
})
wk.setup {
  disable = {
    filetypes = { "TelescopePrompt", "dashboard" }
  }
}
