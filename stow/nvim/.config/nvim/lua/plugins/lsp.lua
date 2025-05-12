return {
  -- #######################
  -- override default config
  -- #######################

  -- easily config neovim lsp
  {
    "neovim/nvim-lspconfig",
    opts = function()
      -- keymaps for lspconfig must be set in opts function: https://www.lazyvim.org/plugins/lsp#%EF%B8%8F-customizing-lsp-keymaps
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      keys[#keys + 1] = { "<F18>", vim.lsp.buf.rename, noremap = true, desc = "Rename (Ctr+F6)" }
      keys[#keys + 1] = { "<M-CR>", vim.lsp.buf.code_action, noremap = true, desc = "Code action (Ctrl+Enter)" }
    end,
  },
}
