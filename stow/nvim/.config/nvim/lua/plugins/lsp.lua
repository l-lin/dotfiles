return {
  -- #######################
  -- override default config
  -- #######################

  -- easily config neovim lsp
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            { "<F18>", vim.lsp.buf.rename, noremap = true, desc = "Rename (Ctr+F6)", has = "rename" },
            { "<M-CR>", vim.lsp.buf.code_action, noremap = true, desc = "Code action (Ctrl+Enter)", has = "codeAction" },
            -- remove LazyVim LSP keymaps and use NeoVim default ones
            { "gr", false }, -- grr by default
            { "gI", false }, -- gri by default
            { "gy", false }, -- grt by default
          },
        },
      },
    },
  },
}
