local wk = require('which-key')
wk.register({ c = { name = "Code" } }, { prefix = "<leader>" })
wk.register({ c = { name = "Check spelling" } }, { prefix = "<leader>l" })
wk.register({ d = { name = "Dap" } }, { prefix = "<leader>" })
wk.register({ f = { name = "Find" } }, { prefix = "<leader>" })
wk.register({ g = { name = "Git" } }, { prefix = "<leader>" })
wk.register({ g = { name = "Git" } }, { prefix = "<leader>f" })
wk.register({ l = { name = "Language" } }, { prefix = "<leader>" })
wk.register({ n = { name = "Navigation" } }, { prefix = "<leader>" })
wk.register({ r = { name = "Search and replace" } }, { prefix = "<leader>" })
wk.register({ t = { name = "Markdown table mode" } }, { prefix = "<leader>" })
wk.register({ t = { name = "Text" } }, { prefix = "<leader>f" })
wk.register({ v = { name = "Nvim" } }, { prefix = "<leader>" })
wk.register({ w = { name = "Whitespace" } }, { prefix = "<leader>" })
wk.register({ x = { name = "Trouble" } }, { prefix = "<leader>" })
wk.setup {
  disable = {
    filetypes = { 'TelescopePrompt', 'dashboard' }
  }
}
